import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';
import 'registry.dart';
import 'storage.dart';
import 'labels.dart';
import 'parameter_input.dart';
import 'editor_catalog.dart';
import 'basic_inspector.dart';
import 'dialog_editor.dart';
import 'motion_tryout.dart';
import 'workbench_preview.dart';

const ink = Color(0xff101420),
    panel = Color(0xff181e2b),
    line = Color(0xff2b3447),
    muted = Color(0xff96a2ba),
    mint = Color(0xffa5ecd7),
    violet = Color(0xffb6b5ff);
const encoder = JsonEncoder.withIndent('  ');
void main() => runApp(const GlassLab());

class GlassLab extends StatefulWidget {
  const GlassLab({super.key, this.initialAdvanced = false});
  final bool initialAdvanced;
  @override
  State<GlassLab> createState() => _GlassLabState();
}

class _GlassLabState extends State<GlassLab> {
  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    if (sheetSetter != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) sheetSetter?.call(() {});
      });
    }
  }

  Json scene = prepareScene(initialScene());
  String? selected = 'node-1';
  bool global = false, snap = true;
  bool advancedMode = false;
  bool sidebarOpen = true;
  String sidebarSection = 'components';
  double zoom = .85;
  String tab = '属性';
  final messenger = GlobalKey<ScaffoldMessengerState>();
  final navigator = GlobalKey<NavigatorState>();
  final canvasBoard = GlobalKey();
  String? recoveryText;
  String saveStatus = '布局保存在当前浏览器';
  StateSetter? sheetSetter;
  final past = <String>[], future = <String>[], events = <String>[];
  int counter = 100;
  late Runtime runtime;
  @override
  void initState() {
    super.initState();
    advancedMode = widget.initialAdvanced;
    final saved = readSaved();
    try {
      if (saved != null) {
        final parsed = jsonDecode(saved) as Json;
        validateScene(parsed, legacy: true);
        scene = prepareScene(parsed);
        selected = (scene['modules'] as List).isEmpty
            ? null
            : scene['modules'][0]['id'];
      }
    } catch (_) {
      recoveryText = saved;
    }
    runtime = Runtime(() => setState(() {}), recordEvent);
  }

  @override
  void dispose() {
    runtime.dispose();
    super.dispose();
  }

  List get modules => scene['modules'] as List;
  Json? get active {
    for (final m in modules) {
      if (m['id'] == selected) return m as Json;
    }
    return null;
  }

  String? commit(
    Json next, {
    bool history = true,
    bool report = true,
    bool importLayout = false,
  }) {
    try {
      validateScene(next, previous: scene, legacy: importLayout);
      next = prepareScene(next);
      if (jsonEncode(next) == jsonEncode(scene)) return null;
      if (history) {
        past.add(jsonEncode(scene));
        if (past.length > 60) past.removeAt(0);
        future.clear();
      }
      setState(() => scene = next);
      persist();
      return null;
    } catch (e) {
      final error = e is FormatException ? e.message : '参数格式不正确，请检查配置';
      if (report) message('未应用：$error');
      return error.toString();
    }
  }

  String? mutate(
    void Function(Json) edit, {
    bool history = true,
    bool report = true,
  }) {
    final next = clone(scene);
    edit(next);
    return commit(next, history: history, report: report);
  }

  void persist() {
    final ok = recoveryText == null && saveScene(jsonEncode(scene));
    final status = recoveryText != null
        ? '恢复模式：旧布局未覆盖'
        : ok
        ? '布局已保存在当前浏览器'
        : '保存失败，请导出布局备份';
    if (mounted) setState(() => saveStatus = status);
  }

  void message(String text) => messenger.currentState?.showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );
  void recordEvent(String value) {
    if (!mounted) return;
    setState(() {
      events.insert(0, value);
      if (events.length > 60) events.removeLast();
    });
  }

  void undo(bool redo) {
    final from = redo ? future : past, to = redo ? past : future;
    if (from.isEmpty) return;
    to.add(jsonEncode(scene));
    final restored = jsonDecode(from.removeLast()) as Json;
    setState(() => scene = restored);
    persist();
  }

  void add(String type, {Offset? at}) {
    if (!advancedMode && basicEntryFor(type) == null) {
      message('这种自定义内容请在高级模式添加');
      return;
    }
    var id = ++counter;
    while (modules.any((m) => m['id'] == 'node-$id')) {
      id = ++counter;
    }
    final p =
        at ??
        Offset(
          36 + (modules.length % 3) * 45.0,
          32 + (modules.length % 6) * 55.0,
        );
    final next = advancedMode ? module(type, id) : createBasicModule(type, id);
    next['x'] = (at != null && snap ? (p.dx / 8).round() * 8.0 : p.dx).clamp(
      0,
      1200 - number(next['w']),
    );
    next['y'] = (at != null && snap ? (p.dy / 8).round() * 8.0 : p.dy).clamp(
      0,
      1200 - number(next['h']),
    );
    final error = mutate((s) => (s['modules'] as List).add(next));
    if (error != null) return;
    setState(() {
      selected = 'node-$id';
      global = false;
    });
  }

  void duplicate() {
    final m = active;
    if (m == null) return;
    final copy = clone(m);
    var id = ++counter;
    while (modules.any((m) => m['id'] == 'node-$id')) {
      id = ++counter;
    }
    copy['id'] = 'node-$id';
    copy['x'] = ((copy['x'] as num) + 24).clamp(0, 1200 - number(copy['w']));
    copy['y'] = ((copy['y'] as num) + 24).clamp(0, 1200 - number(copy['h']));
    if (mutate((s) => (s['modules'] as List).add(copy)) != null) return;
    setState(() => selected = copy['id']);
  }

  void remove() {
    if (active == null) return;
    final id = selected;
    mutate((s) => (s['modules'] as List).removeWhere((m) => m['id'] == id));
    setState(() => selected = modules.isEmpty ? null : modules.last['id']);
  }

  void changeEditorMode(bool advanced) => setState(() {
    advancedMode = advanced;
    tab = '属性';
  });

  String? replaceModule(Json replacement) {
    final index = modules.indexWhere((m) => m['id'] == replacement['id']);
    if (index < 0) return '这个组件已被移除，请重新选择';
    return mutate((s) => s['modules'][index] = replacement, report: false);
  }

  Future<void> runPreview(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !context.mounted) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => WorkbenchPreview(scene: clone(scene))),
    );
  }

  String? editPath(List<dynamic> path, dynamic value, {bool report = true}) {
    return mutate((s) {
      dynamic cur = s;
      for (final p in path.take(path.length - 1)) {
        cur = cur[p];
      }
      if (path.last == 'type' && kindAt(s, path) == 'enum:component') {
        if (path.length == 3 && path.first == 'modules') {
          final replacement = switchComponent({
            'type': cur['type'],
            ...cur['props'],
          }, value);
          cur['type'] = replacement.remove('type');
          cur['props'] = replacement;
        } else {
          final location = kindAt(s, path.sublist(0, path.length - 1));
          final replacement = switchComponent(
            cur as Map,
            value,
            slot: location.startsWith('slot:') ? location.substring(5) : 'root',
          );
          cur
            ..clear()
            ..addAll(replacement);
        }
      } else if (path.last == 'action' && cur is Map) {
        final old = Map<String, dynamic>.from(cur);
        cur
          ..clear()
          ..['action'] = value;
        for (final k in fieldsFor('action', cur).keys) {
          if (k != 'action' && old.containsKey(k)) cur[k] = old[k];
        }
      } else if (path.last == 'type' && kindAt(s, path) == 'enum:gradient') {
        cur['type'] = value;
        cur.removeWhere((k, _) => !fieldsFor('gradient', cur).containsKey(k));
      } else {
        cur[path.last] = value;
      }
    }, report: report);
  }

  Widget tool(IconData icon, String tip, VoidCallback? onTap) => IconButton(
    tooltip: tip,
    onPressed: onTap,
    icon: Icon(icon, size: 19),
    visualDensity: VisualDensity.compact,
  );
  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: navigator,
    scaffoldMessengerKey: messenger,
    debugShowCheckedModeBanner: false,
    title: '玻璃组件实验台',
    locale: const Locale('zh', 'CN'),
    supportedLocales: const [Locale('zh', 'CN')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: ink,
      colorScheme: ColorScheme.fromSeed(
        seedColor: mint,
        brightness: Brightness.dark,
        surface: panel,
      ),
      fontFamily: 'LabSans',
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 13),
        labelLarge: TextStyle(fontSize: 12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ink,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: line),
        ),
      ),
      dividerColor: line,
    ),
    home: Builder(builder: (appContext) => _workspace(appContext)),
  );
  Widget _workspace(BuildContext appContext) => Scaffold(
    body: LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 1180, small = c.maxWidth < 820;
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final compactCanvas =
            (c.maxWidth -
                (small || !sidebarOpen ? 64 : 344) -
                (wide ? 330 : 0)) <
            700 * textScale;
        return Column(
          children: [
            if (recoveryText != null)
              MaterialBanner(
                content: const Text('旧布局未通过校验，原数据已保留。请导出后修复；当前演示不会覆盖旧布局。'),
                actions: [
                  TextButton(
                    onPressed: () =>
                        downloadText('glasslab-original.json', recoveryText!),
                    child: const Text('导出旧布局'),
                  ),
                  TextButton(
                    onPressed: () {
                      if (backupScene(recoveryText!)) {
                        setState(() => recoveryText = null);
                        persist();
                      } else {
                        message('无法保存原数据备份，请先导出旧布局');
                      }
                    },
                    child: const Text('使用当前画布'),
                  ),
                ],
              ),
            Container(
              height: 70 * textScale.clamp(1, 1.6),
              padding: EdgeInsets.symmetric(horizontal: small ? 14 : 24),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: line)),
              ),
              child: Row(
                children: [
                  if (!small || textScale <= 1.3)
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(colors: [violet, mint]),
                      ),
                      child: const Icon(Icons.blur_on, color: ink, size: 23),
                    ),
                  if (!small || textScale <= 1.3) const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '玻璃实验台',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: small ? 18 : 21,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.7,
                      ),
                    ),
                  ),
                  if (wide && textScale <= 1.3) ...[
                    const SizedBox(width: 18),
                    const Text('/  交互与样式预览', style: TextStyle(color: muted)),
                    const Icon(Icons.circle, color: mint, size: 6),
                    const SizedBox(width: 7),
                    const Text(
                      '真实组件渲染',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                    const SizedBox(width: 20),
                  ],
                  if (wide)
                    tool(
                      Icons.undo,
                      '撤销',
                      past.isEmpty ? null : () => undo(false),
                    ),
                  if (wide)
                    tool(
                      Icons.redo,
                      '重做',
                      future.isEmpty ? null : () => undo(true),
                    ),
                  const SizedBox(width: 8),
                  KeyedSubtree(
                    key: const ValueKey('run-preview'),
                    child: wide && textScale <= 1.3
                        ? TextButton.icon(
                            onPressed: () => runPreview(appContext),
                            icon: const Icon(Icons.play_arrow, size: 18),
                            label: const Text('运行预览'),
                          )
                        : tool(
                            Icons.play_arrow,
                            '运行预览',
                            () => runPreview(appContext),
                          ),
                  ),
                  if (wide && textScale <= 1.3)
                    TextButton.icon(
                      key: const ValueKey('editor-mode'),
                      onPressed: () => changeEditorMode(!advancedMode),
                      icon: Icon(
                        advancedMode ? Icons.code : Icons.widgets_outlined,
                        size: 16,
                      ),
                      label: Text(advancedMode ? '高级模式' : '普通模式'),
                    )
                  else
                    KeyedSubtree(
                      key: const ValueKey('editor-mode'),
                      child: tool(
                        advancedMode ? Icons.code : Icons.widgets_outlined,
                        advancedMode ? '切换到普通模式' : '切换到高级模式',
                        () => changeEditorMode(!advancedMode),
                      ),
                    ),
                  if (advancedMode && !wide)
                    tool(
                      Icons.code,
                      '布局配置',
                      () => showJson(appContext, whole: true),
                    )
                  else if (advancedMode)
                    OutlinedButton.icon(
                      onPressed: () => showJson(appContext, whole: true),
                      icon: const Icon(Icons.code, size: 16),
                      label: const Text('布局配置'),
                    ),
                  const SizedBox(width: 8),
                  if (!wide)
                    tool(
                      Icons.file_download_outlined,
                      '导出布局',
                      () => downloadText(
                        'glasslab-layout.json',
                        encoder.convert(scene),
                      ),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () => downloadText(
                        'glasslab-layout.json',
                        encoder.convert(scene),
                      ),
                      icon: const Icon(Icons.file_download_outlined, size: 16),
                      label: Text(advancedMode ? '导出布局' : '保存布局'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  workspaceRail(appContext, small: small, wide: wide),
                  if (!small && sidebarOpen)
                    SizedBox(width: 280, child: palette(appContext)),
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          height: 58,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: line)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.dashboard_customize_outlined,
                                size: 18,
                                color: muted,
                              ),
                              const SizedBox(width: 8),
                              if (!compactCanvas ||
                                  (c.maxWidth >= 390 && textScale <= 1.3))
                                Text(
                                  advancedMode ? '自由画布' : '编辑画布',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              const SizedBox(width: 10),
                              if (!compactCanvas)
                                Text(
                                  '${modules.length} 模块',
                                  style: const TextStyle(
                                    color: muted,
                                    fontSize: 11,
                                  ),
                                ),
                              const Spacer(),
                              tool(
                                Icons.remove,
                                '缩小',
                                () => setState(
                                  () => zoom = (zoom - .1).clamp(.4, 1.5),
                                ),
                              ),
                              Text(
                                '${(zoom * 100).round()}%',
                                style: const TextStyle(
                                  fontFeatures: [FontFeature.tabularFigures()],
                                  color: muted,
                                ),
                              ),
                              tool(
                                Icons.add,
                                '放大',
                                () => setState(
                                  () => zoom = (zoom + .1).clamp(.4, 1.5),
                                ),
                              ),
                              if (!compactCanvas)
                                TextButton.icon(
                                  onPressed: () => setState(() => snap = !snap),
                                  icon: Icon(
                                    Icons.grid_4x4,
                                    size: 15,
                                    color: snap ? mint : muted,
                                  ),
                                  label: Text(snap ? '吸附 8px' : '自由移动'),
                                ),
                              if (!wide && !small)
                                tool(
                                  Icons.tune,
                                  '属性检查器',
                                  () => showInspector(appContext),
                                ),
                            ],
                          ),
                        ),
                        Expanded(child: canvas(appContext)),
                        Container(
                          height: 34 * textScale.clamp(1, 2),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: line)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.save_outlined,
                                size: 13,
                                color: muted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  saveStatus,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: muted,
                                  ),
                                ),
                              ),
                              if (small)
                                tool(Icons.download, '下载示例工程', downloadProject)
                              else
                                const TextButton(
                                  onPressed: downloadProject,
                                  child: const Text(
                                    '下载示例工程 ↗',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                              if (!small)
                                TextButton(
                                  onPressed: () {
                                    setState(
                                      () => tab = advancedMode ? '事件' : '试用记录',
                                    );
                                    if (!wide) showInspector(appContext);
                                  },
                                  child: Text(
                                    '${advancedMode ? '调用事件' : '试用记录'} ${events.length}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (wide) SizedBox(width: 330, child: inspector(appContext)),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
  Widget workspaceRail(
    BuildContext context, {
    required bool small,
    required bool wide,
  }) => Material(
    color: const Color(0xff151a25),
    child: SizedBox(
      width: 64,
      child: Column(
        children: [
          const SizedBox(height: 12),
          for (final section in const [
            ('components', '组件', Icons.add_box_outlined),
            ('layers', '图层', Icons.layers_outlined),
            ('appearance', '外观与动效', Icons.palette_outlined),
            ('properties', '组件属性', Icons.tune),
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: IconButton(
                key: ValueKey('nav-${section.$1}'),
                tooltip: section.$2,
                isSelected:
                    section.$1 == (global ? 'appearance' : sidebarSection),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? mint.withValues(alpha: .14)
                        : Colors.transparent,
                  ),
                  foregroundColor: WidgetStateProperty.resolveWith(
                    (states) =>
                        states.contains(WidgetState.selected) ? mint : muted,
                  ),
                ),
                icon: Icon(section.$3, size: 23),
                onPressed: () {
                  if (section.$1 == 'appearance' ||
                      section.$1 == 'properties') {
                    setState(() {
                      global = section.$1 == 'appearance';
                      tab = '属性';
                    });
                    if (!wide) showInspector(context);
                  } else {
                    setState(() {
                      sidebarSection = section.$1;
                      sidebarOpen = true;
                      global = false;
                    });
                    if (small) showPalette(context);
                  }
                },
              ),
            ),
        ],
      ),
    ),
  );

  Widget palette(BuildContext appContext) {
    final small = MediaQuery.sizeOf(appContext).width < 820;
    void close() {
      if (small) {
        Navigator.of(appContext).pop();
      } else {
        setState(() => sidebarOpen = false);
      }
    }

    return Material(
      color: panel,
      shape: const Border(right: BorderSide(color: line)),
      child: sidebarSection == 'components'
          ? BasicPalette(
              onCollapse: close,
              onAdd: (type) {
                add(type);
                if (small) close();
              },
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '图层',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: close,
                        tooltip: '收起图层面板',
                        icon: const Icon(Icons.chevron_left, size: 20),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      if (modules.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('添加组件后，可在这里选择它。'),
                        ),
                      for (final raw in modules.reversed)
                        ListTile(
                          key: ValueKey('layer-${raw['id']}'),
                          selected: selected == raw['id'] && !global,
                          selectedColor: mint,
                          leading: Icon(
                            basicEntryFor(raw['type'])?.icon ??
                                Icons.widgets_outlined,
                            size: 20,
                          ),
                          title: Text(
                            basicEntryFor(raw['type'])?.title ?? '自定义内容',
                            style: const TextStyle(fontSize: 13),
                          ),
                          trailing: Text(
                            '${modules.indexOf(raw) + 1}',
                            style: const TextStyle(color: muted, fontSize: 11),
                          ),
                          onTap: () {
                            setState(() {
                              selected = raw['id'];
                              global = false;
                              tab = '属性';
                            });
                            if (small) close();
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  IconData _typeIcon(String type) =>
      basicEntryFor(type)?.icon ?? Icons.layers_outlined;

  Widget canvas(BuildContext appContext) {
    final theme = glassTheme(Map<String, dynamic>.from(scene['theme']));
    final board = Theme(
      data: ThemeData(
        brightness: theme.brightness,
        textTheme: theme.textTheme,
        iconTheme: IconThemeData(
          size: theme.layout.iconSize,
          color: theme.foregroundColor,
        ),
        fontFamily: 'LabSans',
        colorScheme:
            theme.colorScheme ??
            ColorScheme.fromSeed(
              seedColor: theme.accentColor,
              brightness: theme.brightness,
            ),
        extensions: [theme],
      ),
      child: MediaQuery(
        data: MediaQuery.of(appContext).copyWith(
          disableAnimations:
              !advancedMode || MediaQuery.of(appContext).disableAnimations,
          highContrast:
              MediaQuery.of(appContext).highContrast ||
              theme.accessibility.highContrast,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: GlassBackdrop(
            child: Stack(
              key: canvasBoard,
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    key: const ValueKey('canvas-background'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() {
                      selected = null;
                      global = false;
                    }),
                    child: CustomPaint(
                      painter: _Grid(theme.brightness == Brightness.dark),
                    ),
                  ),
                ),
                for (final raw in modules)
                  previewModule(raw as Json, appContext),
                if (modules.isEmpty)
                  const Center(
                    child: Text('从左侧添加第一个组件', style: TextStyle(fontSize: 20)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    return Container(
      color: const Color(0xff111722),
      child: DragTarget<String>(
        onAcceptWithDetails: (d) {
          final box =
              canvasBoard.currentContext?.findRenderObject() as RenderBox?;
          if (box != null) add(d.data, at: box.globalToLocal(d.offset));
        },
        builder: (context, candidates, rejected) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: SizedBox(
                width: 1200 * zoom,
                height: 1200 * zoom,
                child: Transform.scale(
                  scale: zoom,
                  alignment: Alignment.topLeft,
                  child: OverflowBox(
                    alignment: Alignment.topLeft,
                    minWidth: 1200,
                    maxWidth: 1200,
                    minHeight: 1200,
                    maxHeight: 1200,
                    child: board,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget previewModule(Json m, BuildContext appContext) {
    final id = m['id'] as String;
    final chosen = selected == id && !global;
    // Drag handles must win before the surrounding canvas scroll gestures.
    final header = MediaQuery(
      data: MediaQuery.of(
        appContext,
      ).copyWith(gestureSettings: const DeviceGestureSettings(touchSlop: 4)),
      child: GestureDetector(
        dragStartBehavior: DragStartBehavior.down,
        behavior: HitTestBehavior.opaque,
        key: ValueKey('header-$id'),
        onTap: () => setState(() {
          selected = id;
          global = false;
        }),
        onPanStart: (_) {
          past.add(jsonEncode(scene));
          if (past.length > 60) past.removeAt(0);
          future.clear();
          setState(() {
            selected = id;
            global = false;
          });
        },
        onPanUpdate: (d) => setState(() {
          m['x'] = (number(m['x']) + d.delta.dx).clamp(
            0,
            (1200 - number(m['w'])).clamp(0, 1200),
          );
          m['y'] = (number(m['y']) + d.delta.dy).clamp(
            0,
            (1200 - number(m['h'])).clamp(0, 1200),
          );
        }),
        onPanEnd: (_) {
          setState(() {
            if (snap) {
              m['x'] = ((number(m['x']) / 8).round() * 8.0).clamp(
                0,
                1200 - number(m['w']),
              );
              m['y'] = ((number(m['y']) / 8).round() * 8.0).clamp(
                0,
                1200 - number(m['h']),
              );
            }
          });
          persist();
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.move,
          child: Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: chosen ? const Color(0xff696ad5) : const Color(0xcc20283a),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(7),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.drag_indicator,
                  size: 13,
                  color: Colors.white70,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    advancedMode
                        ? chineseLabel(m['type'])
                        : basicEntryFor(m['type'])?.title ?? '自定义内容',
                    maxLines: 1,
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
                if (chosen && number(m['w']) >= 100) ...[
                  InkWell(
                    onTap: duplicate,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.copy, size: 13, color: Colors.white),
                    ),
                  ),
                  InkWell(
                    onTap: remove,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 13, color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    final resize = Positioned(
      right: 0,
      bottom: 0,
      child: MediaQuery(
        data: MediaQuery.of(
          appContext,
        ).copyWith(gestureSettings: const DeviceGestureSettings(touchSlop: 4)),
        child: GestureDetector(
          dragStartBehavior: DragStartBehavior.down,
          onPanStart: (_) {
            past.add(jsonEncode(scene));
            if (past.length > 60) past.removeAt(0);
            future.clear();
          },
          onPanUpdate: (d) => setState(() {
            final min = requiredFrame(m);
            m['w'] = (number(m['w']) + d.delta.dx).clamp(
              min.width,
              (1200 - number(m['x'])).clamp(70, 1100),
            );
            m['h'] = (number(m['h']) + d.delta.dy).clamp(
              min.height,
              (1200 - number(m['y'])).clamp(65, 1100),
            );
          }),
          onPanEnd: (_) => persist(),
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeDownRight,
            child: Container(
              width: 18,
              height: 18,
              color: const Color(0xff696ad5),
              child: const Icon(
                Icons.south_east,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
    return Positioned(
      key: ValueKey(id),
      left: number(m['x']),
      top: number(m['y']),
      width: number(m['w']),
      height: number(m['h']),
      child: Column(
        children: [
          header,
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: chosen ? const Color(0xff8c8cff) : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: ExcludeFocus(
                      excluding: !advancedMode,
                      child: IgnorePointer(
                        ignoring: !advancedMode,
                        child: Builder(
                          builder: (context) {
                            try {
                              return runtime.build(
                                {...(m['props'] as Map), 'type': m['type']},
                                context,
                                '$id/root',
                              );
                            } catch (e) {
                              return ColoredBox(
                                color: const Color(0xff4b2333),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Text(
                                      '参数无法渲染\n$e',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  if (!advancedMode)
                    Positioned.fill(
                      child: Semantics(
                        button: true,
                        label:
                            '选择${basicEntryFor(m['type'])?.title ?? '自定义内容'}',
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() {
                            selected = id;
                            global = false;
                            tab = '属性';
                          }),
                        ),
                      ),
                    ),
                  if (chosen) resize,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget inspector(BuildContext appContext) => Material(
    color: panel,
    shape: const Border(left: BorderSide(color: line)),
    child: Column(
      children: [
        Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              for (final label
                  in advancedMode ? ['属性', '配置', '事件'] : ['属性', '试用记录'])
                TextButton(
                  onPressed: () => setState(() => tab = label),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: tab == label ? mint : muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const Spacer(),
              tool(
                Icons.public,
                '全局主题',
                () => setState(() => global = !global),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: tab == '事件' || tab == '试用记录'
              ? eventPanel()
              : tab == '配置'
              ? jsonPanel(appContext)
              : propertyPanel(appContext),
        ),
      ],
    ),
  );
  Widget propertyPanel(BuildContext appContext) {
    if (!advancedMode) return basicPropertyPanel(appContext);
    final m = active;
    final idx = modules.indexOf(m);
    return ListView(
      key: const ValueKey('properties'),
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: mint.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(
                global ? Icons.palette_outlined : _typeIcon(m?['type'] ?? ''),
                color: mint,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                global ? '全局主题' : chineseLabel(m?['type'] ?? '选择一个模块'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          global
              ? '影响画布中所有组件；明确设置的组件值会覆盖主题，可使用“恢复继承”。'
              : componentHelp[m?['type']] ?? '选择一个模块查看功能与参数。',
          style: const TextStyle(fontSize: 11, color: muted, height: 1.5),
        ),
        const SizedBox(height: 16),
        if (!global && m != null)
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: duplicate,
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('复制模块'),
              ),
              TextButton.icon(
                onPressed: remove,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('删除模块'),
              ),
            ],
          ),
        if (global)
          ...fields(scene['theme'] as Map, ['theme'], appContext)
        else if (m != null) ...[
          const Text(
            '画布布局',
            style: TextStyle(color: muted, fontSize: 10, letterSpacing: 1),
          ),
          ...fields(
            {
              for (final k in ['x', 'y', 'w', 'h']) k: m[k],
            },
            ['modules', idx],
            appContext,
          ),
          const Divider(height: 28),
          field('type', m['type'], ['modules', idx, 'type'], appContext, 0),
          const Text(
            '组件参数',
            style: TextStyle(color: muted, fontSize: 10, letterSpacing: 1),
          ),
          ...fields(m['props'] as Map, ['modules', idx, 'props'], appContext),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => showJson(appContext),
            icon: const Icon(Icons.code, size: 14),
            label: const Text('编辑完整配置'),
          ),
          TextButton(
            onPressed: () {
              mutate((s) {
                s['modules'][idx]['props'] = clone(
                  componentDefaults[m['type']]!,
                );
              });
            },
            child: const Text('恢复此组件默认值'),
          ),
        ],
        const Divider(height: 28),
        const Text('进阶输入', style: TextStyle(color: muted, fontSize: 11)),
        const SizedBox(height: 8),
        const Text(
          '数字与文字支持回车或移开焦点应用，错误值会保留并提示。\n模块宽高控制外框；内部宽高控制实际表面，仍受可用空间限制。\n“未设置”表示继承默认值；明确设置会覆盖主题。\n复杂值可在配置中编辑，原数据中未适配的字段只保留备份，不作为有效参数。',
          style: TextStyle(color: muted, fontSize: 10, height: 1.7),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget basicPropertyPanel(BuildContext appContext) {
    final current = active;
    final index = modules.indexOf(current);
    return ListView(
      key: const ValueKey('properties'),
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          global
              ? '整体外观'
              : basicEntryFor(current?['type'] ?? '')?.title ?? '自定义内容',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        if (global) ...[
          const Text('影响整个画布；已单独设置的外观会继续保留。'),
          const SizedBox(height: 14),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('深色外观'),
            value: scene['theme']['brightness'] == 'dark',
            onChanged: (v) =>
                editPath(['theme', 'brightness'], v ? 'dark' : 'light'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('高对比度'),
            value: scene['theme']['accessibility']['highContrast'] == true,
            onChanged: (v) =>
                editPath(['theme', 'accessibility', 'highContrast'], v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('减少透明效果'),
            value:
                scene['theme']['accessibility']['reduceTransparency'] == true,
            onChanged: (v) =>
                editPath(['theme', 'accessibility', 'reduceTransparency'], v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('减少动画'),
            value: scene['theme']['accessibility']['reduceMotion'] == true,
            onChanged: (v) =>
                editPath(['theme', 'accessibility', 'reduceMotion'], v),
          ),
          const Divider(height: 28),
          MotionTryout(
            theme: Map<String, dynamic>.from(scene['theme']),
            onApply: (motion) =>
                editPath(['theme', 'motion'], motion, report: false),
          ),
        ] else if (current != null) ...[
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: duplicate,
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('复制组件'),
              ),
              TextButton.icon(
                onPressed: remove,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('删除组件'),
              ),
            ],
          ),
          if (DialogEditor.supports(current)) ...[
            if (current['type'] != 'showGlassDialog' &&
                current['type'] != 'GlassDialog')
              TextButton(
                onPressed: () {
                  final next = clone(current);
                  next['props']['onPressed'] = 'log';
                  replaceModule(next);
                },
                child: const Text('改为普通点击操作'),
              ),
            DialogEditor(
              key: ValueKey('dialog-${current['id']}'),
              module: current,
              theme: Map<String, dynamic>.from(scene['theme']),
              onApply: replaceModule,
              onAdvanced: () => changeEditorMode(true),
              onEvent: recordEvent,
            ),
          ] else
            BasicInspector(
              key: ValueKey('basic-${current['id']}'),
              module: current,
              onApply: replaceModule,
              onAdvanced: () => changeEditorMode(true),
            ),
          const Divider(height: 28),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('编辑器中的位置与大小'),
            children: [
              for (final k in ['x', 'y', 'w', 'h'])
                field(k, current[k], ['modules', index, k], appContext, 0),
            ],
          ),
        ] else
          const Text('从左侧添加内容，或选择一个组件。'),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => changeEditorMode(true),
          child: const Text('切换高级模式'),
        ),
      ],
    );
  }

  List<Widget> fields(
    Map data,
    List<dynamic> path,
    BuildContext appContext, [
    int depth = 0,
  ]) {
    final kind = kindAt(scene, path);
    final shown = kind == 'module'
        ? Map<String, dynamic>.from(data)
        : editorFields(data, kind);
    if (path.lastOrNull == 'props' && !data.containsKey('type'))
      shown.remove('type');
    return [
      for (final entry in shown.entries)
        field(entry.key, entry.value, [...path, entry.key], appContext, depth),
    ];
  }

  Widget field(
    String key,
    dynamic value,
    List<dynamic> path,
    BuildContext appContext,
    int depth,
  ) {
    if (key == '_nodeId') return const SizedBox.shrink();
    var kind = kindAt(scene, path);
    final parentKind = kindAt(scene, path.sublist(0, path.length - 1));
    if (parentKind.startsWith('component:') || parentKind.startsWith('slot:')) {
      if (key == 'type' && path[path.length - 2] == 'props')
        kind = 'unsupported';
    }
    if (kind == 'unsupported')
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          '未适配字段（${chineseLabel(key)}）：仅保留原数据，请在配置中查看。',
          style: const TextStyle(fontSize: 11, color: muted),
        ),
      );
    final label = RegExp(r'^\[\d+\]$').hasMatch(key)
        ? '第${int.parse(key.substring(1, key.length - 1)) + 1}项'
        : fieldLabel(parentKind, key);
    final inherit =
        path.length > 3 &&
        [
          'style',
          'padding',
          'margin',
          'duration',
          'width',
          'height',
          'constraints',
          'controlStyle',
          'iconSize',
          'appBarTitleSpacing',
        ].contains(key);
    Widget title() => Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
        if (inherit && value != null)
          IconButton(
            tooltip: '恢复继承',
            icon: const Icon(Icons.restart_alt, size: 16),
            onPressed: () => editPath(path, null),
          ),
      ],
    );
    if (value is Map && kind != 'any')
      return ExpansionTile(
        key: ValueKey('section-${path.join('.')}'),
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.only(left: depth < 2 ? 8 : 0),
        title: title(),
        subtitle: Text(
          value['type'] == null
              ? '${value.length} 个已保存字段'
              : chineseLabel(value['type'].toString()),
          style: const TextStyle(fontSize: 10, color: muted),
        ),
        children: [
          ...fields(value, path, appContext, depth + 1),
          TextButton(
            onPressed: () => jsonValue(appContext, key, value, path),
            child: const Text('编辑完整结构'),
          ),
        ],
      );
    if (value is List && kind.startsWith('list:'))
      return ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.only(left: depth < 2 ? 8 : 0),
        title: title(),
        subtitle: Text(
          '${value.length} 项 · 可编辑组合',
          style: const TextStyle(fontSize: 10, color: muted),
        ),
        children: [
          for (var i = 0; i < value.length; i++)
            field('[$i]', value[i], [...path, i], appContext, depth + 1),
          TextButton(
            onPressed: () => jsonValue(appContext, key, value, path),
            child: const Text('编辑 / 添加列表项'),
          ),
        ],
      );
    if (value is bool)
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: (v) => editPath(path, v),
      );
    if (kind.startsWith('state:')) kind = kind.substring(6);
    List<String>? options;
    if (kind == 'enum:component')
      options = typesAt(scene, path.sublist(0, path.length - 1));
    else if (kind.startsWith('enum:'))
      options = enumValues(kind.substring(5));
    else if (kind == 'action' && (value is String || value == null))
      options = actionNames.take(7).toList();
    else if (kind == 'controlShape' && (value is String || value == null))
      options = ['circle', 'stadium'];
    if (options != null &&
        (value == null || value is String && options.contains(value)))
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title(),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              itemHeight: null,
              key: ValueKey('$path/$value'),
              initialValue: value,
              isExpanded: true,
              items: [
                for (final option in options)
                  DropdownMenuItem(
                    value: option,
                    child: Text(
                      chineseLabel(option),
                      maxLines: 3,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
              onChanged: options.length == 1 ? null : (v) => editPath(path, v),
            ),
            if (options.length == 1)
              const Text(
                '此位置固定为匹配的组件类型',
                style: TextStyle(fontSize: 10, color: muted),
              ),
          ],
        ),
      );
    if (value is Map ||
        value is List ||
        !['number', 'string', 'color'].contains(kind))
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title(),
            TextButton(
              onPressed: () => jsonValue(appContext, key, value, path),
              child: Text(value == null ? '未设置 · 设置' : '编辑结构化参数'),
            ),
          ],
        ),
      );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title(),
          const SizedBox(height: 4),
          ParameterInput(
            key: ValueKey(path.join('.')),
            value: value,
            numeric: kind == 'number',
            allowNull: value == null || inherit,
            onApply: (v) => editPath(path, v, report: false),
          ),
        ],
      ),
    );
  }

  Widget eventPanel() => Column(
    children: [
      ListTile(
        dense: true,
        title: Text(
          advancedMode ? '真实组件调用日志' : '试用结果记录',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: tool(
          Icons.delete_outline,
          '清空日志',
          () => setState(() => events.clear()),
        ),
      ),
      const Divider(height: 1),
      Expanded(
        child: events.isEmpty
            ? Center(
                child: Text(
                  advancedMode
                      ? '点击画布中的按钮、菜单或输入框\n事件会显示在这里'
                      : '弹窗试用结果会显示在这里。\n运行预览的记录仅在本次会话内保留。',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: muted,
                    height: 1.7,
                    fontSize: 12,
                  ),
                ),
              )
            : ListView.builder(
                itemCount: events.length,
                itemBuilder: (c, i) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.bolt, size: 14, color: mint),
                  title: SelectableText(
                    events[i],
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                    ),
                  ),
                  subtitle: Text(
                    '#${events.length - i}',
                    style: const TextStyle(fontSize: 9, color: muted),
                  ),
                ),
              ),
      ),
    ],
  );
  Widget jsonPanel(BuildContext appContext) {
    final backup = readBackup();
    final data = global
        ? scene['theme']
        : active == null
        ? {}
        : {'type': active!['type'], ...active!['props'] as Map};
    return Column(
      children: [
        if (backup != null)
          TextButton(
            onPressed: () =>
                downloadText('glasslab-before-upgrade.json', backup),
            child: const Text('导出修改前布局备份'),
          ),
        ListTile(
          dense: true,
          title: Text(
            global ? '主题配置' : '当前组件调用',
            style: const TextStyle(fontSize: 12),
          ),
          subtitle: const Text(
            '高级配置用于编辑完整结构、复杂值与嵌套组件',
            style: TextStyle(fontSize: 10, color: muted),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              encoder.convert(data),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: mint,
                height: 1.7,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      Clipboard.setData(
                        ClipboardData(text: encoder.convert(data)),
                      ).then((_) {
                        ScaffoldMessenger.of(appContext).showSnackBar(
                          const SnackBar(content: Text('组件配置已复制')),
                        );
                      }),
                  child: const Text('复制调用'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => showJson(appContext),
                  child: const Text('编辑应用'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void showPalette(BuildContext c) => showModalBottomSheet(
    context: c,
    isScrollControlled: true,
    builder: (_) =>
        SizedBox(height: MediaQuery.sizeOf(c).height * .85, child: palette(c)),
  );
  void showInspector(BuildContext c) => showModalBottomSheet(
    context: c,
    isScrollControlled: true,
    builder: (_) => SizedBox(
      height: MediaQuery.of(c).size.height * .85,
      child: StatefulBuilder(
        builder: (context, rebuild) {
          sheetSetter = rebuild;
          return inspector(c);
        },
      ),
    ),
  ).whenComplete(() => sheetSetter = null);
  Future<void> jsonValue(
    BuildContext c,
    String label,
    dynamic value,
    List<dynamic> path,
  ) async {
    final result = await jsonEditor(
      c,
      chineseLabel(label),
      encoder.convert(value),
      hint: '请使用配置格式（JSON）：数字不加引号，文字和字段名需要双引号。',
    );
    if (result != null) editPath(path, result.value);
  }

  Future<void> showJson(BuildContext c, {bool whole = false}) async {
    final m = active;
    final data = whole
        ? scene
        : global
        ? scene['theme']
        : m == null
        ? {}
        : {'type': m['type'], ...m['props'] as Map};
    final applied = await jsonEditor(
      c,
      whole
          ? '布局配置 · 导入 / 导出'
          : global
          ? '全局主题配置'
          : '组件配置',
      encoder.convert(data),
      hint: whole
          ? '导入只替换当前画布。编辑不发送到服务器。'
          : '修改组件参数、内容或子组件列表。配置字段保留代码原名；字符串需要双引号，数字不加引号。',
    );
    if (applied == null) return;
    final result = applied.value;
    if (result is! Map) {
      ScaffoldMessenger.of(
        c,
      ).showSnackBar(const SnackBar(content: Text('根节点需要 JSON 对象')));
      return;
    }
    if (whole) {
      commit(Map<String, dynamic>.from(result), importLayout: true);
    } else if (global) {
      mutate((s) => s['theme'] = result);
    } else if (m != null) {
      final type = result['type'] ?? m['type'];
      final props = Map<String, dynamic>.from(result)..remove('type');
      mutate((s) {
        final index = (s['modules'] as List).indexWhere(
          (v) => v['id'] == m['id'],
        );
        s['modules'][index]['type'] = type;
        s['modules'][index]['props'] = props;
      });
    }
  }

  Future<_Applied?> jsonEditor(
    BuildContext c,
    String title,
    String initial, {
    String? hint,
  }) async {
    final controller = TextEditingController(text: initial);
    String? error;
    final answer = await showDialog<_Applied>(
      context: c,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          backgroundColor: panel,
          title: Text(title, style: const TextStyle(fontSize: 18)),
          content: SizedBox(
            width: 680,
            height: 480,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hint ?? '',
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: TextField(
                    controller: controller,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      height: 1.6,
                    ),
                    decoration: const InputDecoration(alignLabelWithHint: true),
                  ),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      error!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: controller.text)),
              child: const Text('复制'),
            ),
            FilledButton(
              onPressed: () {
                try {
                  final parsed = jsonDecode(controller.text);
                  if (title.startsWith('布局'))
                    validateScene(
                      parsed as Json,
                      previous: scene,
                      legacy: true,
                    );
                  Navigator.pop(context, _Applied(parsed));
                } catch (e) {
                  update(() => error = '配置格式不正确，请检查引号、逗号和参数类型。');
                }
              },
              child: const Text('应用到画布'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return answer;
  }
}

class _Grid extends CustomPainter {
  _Grid(this.dark);
  final bool dark;
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = (dark ? Colors.white : Colors.indigo).withValues(alpha: .09);
    for (double x = 16; x < s.width; x += 24) {
      for (double y = 16; y < s.height; y += 24) {
        c.drawCircle(Offset(x, y), .7, p);
      }
    }
  }

  @override
  bool shouldRepaint(_Grid old) => old.dark != dark;
}

class _Applied {
  const _Applied(this.value);
  final dynamic value;
}
