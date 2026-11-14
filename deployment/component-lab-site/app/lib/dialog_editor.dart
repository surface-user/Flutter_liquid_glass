import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';
import 'parameter_input.dart';
import 'registry.dart';
import 'labels.dart' show sampleText;

ThemeData _dialogMaterialTheme(LiquidGlassThemeData theme) => ThemeData(
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
);

/// Edits common dialog intentions while keeping the existing module protocol.
class DialogEditor extends StatefulWidget {
  const DialogEditor({
    super.key,
    required this.module,
    required this.onApply,
    required this.onAdvanced,
    this.onEvent,
    this.theme,
  });
  final Json module;
  final String? Function(Json) onApply;
  final VoidCallback onAdvanced;
  final ValueChanged<String>? onEvent;
  final Json? theme;

  static bool supports(Json module) {
    if (['showGlassDialog', 'GlassDialog'].contains(module['type']))
      return true;
    if (!['GlassButton', 'GlassIconButton'].contains(module['type']))
      return false;
    final action = (module['props'] as Map?)?['onPressed'];
    return action == 'dialog' || action is Map && action['action'] == 'dialog';
  }

  static Json effectiveProps(Json module) => {
    ...clone(componentDefaults[module['type']]!),
    ...clone(module['props'] as Json),
  };

  static dynamic _rawContent(Json module) {
    final props = effectiveProps(module);
    final dynamic raw = module['type'] == 'GlassDialog'
        ? module['props']
        : module['type'] == 'showGlassDialog'
        ? props['builder']
        : props['onPressed'] is Map
        ? props['onPressed']['builder'] ?? {'type': 'GlassDialog'}
        : {'type': 'GlassDialog'};
    return raw;
  }

  static Json? contentOf(Json module) {
    final raw = _rawContent(module);
    if (raw == null) return null;
    return clone({
      'type': 'GlassDialog',
      ...clone(componentDefaults['GlassDialog']!),
      if (raw is Map) ...Map<String, dynamic>.from(raw),
    });
  }

  @override
  State<DialogEditor> createState() => _DialogEditorState();
}

class _DialogEditorState extends State<DialogEditor> {
  late Json current = clone(widget.module);
  String? error, result;
  bool opening = false;
  final tryFocus = FocusNode(debugLabel: '试用弹窗');
  late final runtime = Runtime(() {
    if (mounted) setState(() {});
  }, (event) => widget.onEvent?.call(event));
  Json get props => DialogEditor.effectiveProps(current);
  Json get dialog => DialogEditor.contentOf(current) ?? <String, dynamic>{};
  List get actions => dialog['actions'] as List? ?? [];
  bool get dedicated => current['type'] == 'showGlassDialog';
  bool get hasEntry => current['type'] != 'GlassDialog';

  @override
  void didUpdateWidget(DialogEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (jsonEncode(oldWidget.module) != jsonEncode(widget.module)) {
      current = clone(widget.module);
    }
  }

  @override
  void dispose() {
    tryFocus.dispose();
    runtime.dispose();
    super.dispose();
  }

  bool plainText(dynamic node) =>
      node == null || node is Map && node['type'] == 'Text';
  String textOf(dynamic node) =>
      node is Map ? sampleText((node['text'] ?? '').toString()) : '';
  dynamic textWith(dynamic node, String text) => text.isEmpty && node == null
      ? null
      : <String, dynamic>{
          if (node is Map) ...Map<String, dynamic>.from(node),
          'type': 'Text',
          'text': text,
        };
  dynamic actionResult(dynamic action) =>
      action is Map ? action['result'] : null;
  bool simpleAction(dynamic item) {
    if (item is! Map ||
        item['type'] != 'GlassButton' ||
        !plainText(item['child']))
      return false;
    final action = item['onPressed'];
    final value = actionResult(action);
    return (action == 'close' ||
            action is Map && action['action'] == 'close') &&
        (value == null || value is String || value is num || value is bool);
  }

  bool get simple =>
      dialog['type'] == 'GlassDialog' &&
      plainText(dialog['title']) &&
      plainText(dialog['content']) &&
      actions.every(simpleAction);

  String? save(Json next) {
    final failure = widget.onApply(next);
    if (mounted)
      setState(() {
        error = failure;
        if (failure == null) current = clone(next);
      });
    return failure;
  }

  String? editDialog(void Function(Json) edit) {
    final next = clone(current);
    final node = DialogEditor.contentOf(next);
    if (node == null) return '请先在高级模式补充弹窗内容';
    final before = clone(node);
    edit(node);
    final nextProps = next['props'] as Json;
    final target = Map<String, dynamic>.from(
      DialogEditor._rawContent(next) as Map,
    );
    for (final key in {...before.keys, ...node.keys}) {
      if (jsonEncode(before[key]) == jsonEncode(node[key])) continue;
      if (node.containsKey(key)) {
        target[key] = node[key];
      } else {
        target.remove(key);
      }
    }
    if (next['type'] == 'GlassDialog') {
      target.remove('type');
      next['props'] = target;
    } else if (next['type'] == 'showGlassDialog') {
      nextProps['builder'] = target;
    } else {
      final old = nextProps['onPressed'];
      nextProps['onPressed'] = {
        if (old is Map) ...Map<String, dynamic>.from(old),
        'action': 'dialog',
        'builder': target,
      };
    }
    return save(next);
  }

  String? editEntry(void Function(Json) edit) {
    final next = clone(current);
    final before = props, value = props;
    edit(value);
    for (final key in {...before.keys, ...value.keys}) {
      if (jsonEncode(before[key]) != jsonEncode(value[key])) {
        (next['props'] as Json)[key] = value[key];
      }
    }
    return save(next);
  }

  List buttons(Json node) =>
      node['actions'] as List? ?? (node['actions'] = <dynamic>[]);

  Future<void> purpose(String value) async {
    final count = value == 'confirm' ? 2 : 1;
    if (actions.length == count) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('切换弹窗用途'),
        content: const Text('标题和正文会保留，操作按钮会换成所选用途的默认按钮。原按钮文案和返回结果将被替换。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('保留当前按钮'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('切换用途'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    editDialog(
      (node) => node['actions'] = [
        if (count == 2)
          {
            'type': 'GlassButton',
            'child': textNode('取消'),
            'onPressed': {'action': 'close', 'result': '取消'},
          },
        {
          'type': 'GlassButton',
          'child': textNode(count == 2 ? '确认' : '知道了'),
          'onPressed': count == 2
              ? {'action': 'close', 'result': '确认'}
              : 'close',
        },
      ],
    );
  }

  Future<void> tryDialog(BuildContext routeContext) async {
    if (opening) return;
    FocusManager.instance.primaryFocus?.unfocus();
    // Focus listeners commit the last draft before a new route reads it.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !routeContext.mounted || error != null || opening) return;
    final node = DialogEditor.contentOf(current);
    final trialTheme = LiquidGlassTheme.of(routeContext);
    tryFocus.requestFocus();
    setState(() {
      opening = true;
      result = null;
    });
    widget.onEvent?.call('试用弹窗已打开');
    try {
      final value = await showGlassDialog<dynamic>(
        context: routeContext,
        barrierDismissible: dedicated
            ? props['barrierDismissible'] ?? true
            : true,
        motion: dedicated && props['motion'] != null
            ? motion(props['motion'])
            : null,
        builder: (c) => Theme(
          data: _dialogMaterialTheme(trialTheme),
          child: Builder(
            builder: (inner) =>
                runtime.build(node, inner, 'dialog-editor-trial'),
          ),
        ),
      );
      final message = value == null ? '已关闭，未返回结果' : '返回结果：$value';
      widget.onEvent?.call(message);
      if (mounted) setState(() => result = message);
    } finally {
      if (mounted) {
        setState(() => opening = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              !opening &&
              tryFocus.canRequestFocus &&
              ModalRoute.of(context)?.isCurrent == true) {
            tryFocus.requestFocus();
          }
        });
      }
    }
  }

  Widget input(
    String key,
    String label,
    dynamic value,
    String? Function(dynamic) apply, {
    bool numeric = false,
    bool nullable = false,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 5),
        ParameterInput(
          key: ValueKey('dialog-$key'),
          value: value,
          numeric: numeric,
          allowNull: nullable,
          maxLines: lines,
          onApply: apply,
        ),
      ],
    ),
  );

  Widget choice(
    String key,
    String label,
    String value,
    Map<String, String> options,
    ValueChanged<String> apply,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 5),
        Semantics(
          label: label,
          child: DropdownButtonFormField<String>(
            key: ValueKey('dialog-$key-$value'),
            initialValue: value,
            isExpanded: true,
            isDense: false,
            itemHeight: null,
            selectedItemBuilder: (_) => [
              for (final e in options.entries)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  heightFactor: 1,
                  child: Text(
                    e.value,
                    key: ValueKey('dialog-selected-$key-${e.key}'),
                    softWrap: true,
                  ),
                ),
            ],
            items: [
              for (final e in options.entries)
                DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value, softWrap: true),
                ),
            ],
            onChanged: opening
                ? null
                : (value) {
                    if (value != null) apply(value);
                  },
          ),
        ),
      ],
    ),
  );

  String resultKind(dynamic value) => value == null
      ? 'none'
      : value is bool
      ? 'bool'
      : value is num
      ? 'number'
      : 'text';
  void editButton(int index, void Function(Json) edit) => editDialog((node) {
    final items = buttons(node);
    final button = Map<String, dynamic>.from(items[index] as Map);
    edit(button);
    items[index] = button;
  });
  void setResult(int index, dynamic value) => editButton(index, (button) {
    final old = button['onPressed'];
    button['onPressed'] = {
      if (old is Map) ...Map<String, dynamic>.from(old),
      'action': 'close',
      'result': value,
    };
  });

  Widget buttonEditor(int index) {
    final button = actions[index] as Map;
    final value = actionResult(button['onPressed']);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '操作按钮 ${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            input('button-$index-label', '按钮文字', textOf(button['child']), (v) {
              return editDialog((node) {
                final item = (node['actions'] as List)[index] as Map;
                item['child'] = textWith(item['child'], v as String);
              });
            }),
            choice(
              'button-$index-result',
              '关闭后返回',
              resultKind(value),
              const {
                'none': '不返回内容',
                'text': '一段文字',
                'number': '一个数值',
                'bool': '是或否',
              },
              (kind) => setResult(index, switch (kind) {
                'text' => '',
                'number' => 0,
                'bool' => true,
                _ => null,
              }),
            ),
            if (value is String || value is num)
              input('button-$index-value', '返回内容', value, (v) {
                setResult(index, v);
                return error;
              }, numeric: value is num),
            if (value is bool)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('返回“是”'),
                value: value,
                onChanged: (v) => setResult(index, v),
              ),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: index == 0
                      ? null
                      : () => editDialog((node) {
                          final list = buttons(node);
                          final item = list.removeAt(index);
                          list.insert(index - 1, item);
                        }),
                  child: const Text('上移'),
                ),
                TextButton(
                  onPressed: index + 1 == actions.length
                      ? null
                      : () => editDialog((node) {
                          final list = buttons(node);
                          final item = list.removeAt(index);
                          list.insert(index + 1, item);
                        }),
                  child: const Text('下移'),
                ),
                TextButton(
                  onPressed: () =>
                      editDialog((node) => buttons(node).removeAt(index)),
                  child: const Text('移除此按钮'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget contentPreview(BuildContext context, Json node) {
    final data = widget.theme == null
        ? LiquidGlassTheme.of(context)
        : glassTheme(widget.theme!);
    final material = _dialogMaterialTheme(data);
    final contrast =
        MediaQuery.highContrastOf(context) || data.accessibility.highContrast;
    final readable = data.brightness == Brightness.dark
        ? Colors.white
        : const Color(0xff17233b);
    final style = contrast
        ? material.textTheme.bodyMedium!.copyWith(
            foreground: Paint()..color = readable,
          )
        : material.textTheme.bodyMedium!;
    return ExpansionTile(
      key: const ValueKey('dialog-preview-section'),
      initiallyExpanded: true,
      tilePadding: EdgeInsets.zero,
      title: const Text('内容预览（只读）'),
      children: [
        DefaultTextStyle(
          style: style,
          child: Container(
            key: const ValueKey('dialog-content-preview'),
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: contrast
                  ? (data.brightness == Brightness.dark
                        ? const Color(0xff202a3c)
                        : const Color(0xffedf1f8))
                  : data.surfaceColor,
              border: Border.all(
                color: contrast ? readable : material.dividerColor,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            constraints: const BoxConstraints(maxHeight: 240),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (textOf(node['title']).isNotEmpty)
                    Text(
                      textOf(node['title']),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(height: 8),
                  Text(textOf(node['content'])),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      for (final action in actions)
                        Text(textOf(action['child'])),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final node = dialog;
    final width = (node['constraints'] as Map?)?['maxWidth'];
    final pad = node['padding'];
    final style = node['style'];
    var appearance = style == null ? 'inherit' : 'custom';
    for (final name in ['dialog', 'subtle', 'elevatedCard']) {
      if (jsonEncode(style) == jsonEncode(styleJson(presets[name]!)))
        appearance = name;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '弹窗内容与行为',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        const Text('先编辑内容，再试用真实弹窗。入口文字和弹窗正文分别设置。'),
        if (hasEntry && current['type'] == 'GlassIconButton')
          input(
            'entry-tooltip',
            '图标提示文字',
            props['tooltip'] ?? '',
            (v) => editEntry((p) => p['tooltip'] = v),
          ),
        if (hasEntry &&
            current['type'] != 'GlassIconButton' &&
            !plainText(props['child']))
          const Text('入口使用自定义内容，已完整保留。可在高级模式调整入口外观。'),
        if (hasEntry &&
            current['type'] != 'GlassIconButton' &&
            plainText(props['child'])) ...[
          if (dedicated)
            choice('entry', '打开方式', props['triggerKind'] ?? 'button', const {
              'button': '按钮',
              'iconButton': '图标按钮',
              'textLink': '文字链接',
              'actionOnly': '不设置画布入口',
            }, (v) => editEntry((p) => p['triggerKind'] = v)),
          input(
            'entry-label',
            dedicated && props['triggerKind'] == 'iconButton'
                ? '图标提示文字'
                : '入口文字',
            textOf(props['child']),
            (v) => editEntry(
              (p) => p['child'] = textWith(p['child'], v as String),
            ),
          ),
          if (dedicated && props['triggerKind'] == 'iconButton')
            choice('entry-icon', '入口图标', props['triggerIcon'] ?? 'info', const {
              'info': '说明',
              'sparkles': '闪光',
              'settings': '设置',
              'heart': '爱心',
              'add': '添加',
              'check': '勾选',
              'search': '搜索',
              'folder': '文件夹',
              'file': '文件',
              'close': '关闭',
              'home': '主页',
              'arrow': '箭头',
            }, (v) => editEntry((p) => p['triggerIcon'] = v)),
        ],
        if (!simple) ...[
          const SizedBox(height: 16),
          const Text('此弹窗包含自定义内容或操作，已完整保留。请进入高级模式编辑结构；仍可试用原来的弹窗。'),
          TextButton(
            onPressed: widget.onAdvanced,
            child: const Text('在高级模式查看内容'),
          ),
        ] else ...[
          choice(
            'purpose',
            '弹窗用途',
            actions.length > 1 ? 'confirm' : 'info',
            const {'info': '文字说明', 'confirm': '确认操作'},
            purpose,
          ),
          input(
            'title',
            '标题（可留空）',
            textOf(node['title']),
            (v) => editDialog(
              (n) => n['title'] = (v as String).isEmpty
                  ? null
                  : textWith(n['title'], v),
            ),
          ),
          input(
            'body',
            '正文',
            textOf(node['content']),
            (v) => editDialog(
              (n) => n['content'] = textWith(n['content'], v as String),
            ),
            lines: 4,
          ),
          const SizedBox(height: 8),
          contentPreview(context, node),
          for (var i = 0; i < actions.length; i++) buttonEditor(i),
          if (actions.length < 100)
            TextButton.icon(
              onPressed: () => editDialog(
                (n) => buttons(n).add({
                  'type': 'GlassButton',
                  'child': textNode('关闭'),
                  'onPressed': 'close',
                }),
              ),
              icon: const Icon(Icons.add),
              label: const Text('添加操作按钮'),
            ),
          input(
            'max-width',
            '弹窗最大宽度',
            width,
            (v) {
              if (v != null && (v <= 0 || v > 1100)) return '最大宽度需大于0且不超过1100';
              return editDialog(
                (n) => n['constraints'] = {
                  ...?n['constraints'] as Map?,
                  'maxWidth': v,
                },
              );
            },
            numeric: true,
            nullable: true,
          ),
          choice(
            'padding',
            '内容留白',
            pad == null
                ? 'inherit'
                : pad == 16
                ? 'compact'
                : pad == 24
                ? 'standard'
                : pad == 32
                ? 'wide'
                : 'custom',
            {
              'inherit': '跟随页面',
              'compact': '紧凑',
              'standard': '适中',
              'wide': '宽松',
              if (pad != null && ![16, 24, 32].contains(pad))
                'custom': '保留现有留白',
            },
            (v) {
              if (v != 'custom')
                editDialog(
                  (n) => n['padding'] = switch (v) {
                    'compact' => 16,
                    'standard' => 24,
                    'wide' => 32,
                    _ => null,
                  },
                );
            },
          ),
          choice(
            'appearance',
            '弹窗外观',
            appearance,
            {
              'inherit': '跟随页面',
              'dialog': '柔和玻璃',
              'subtle': '轻透玻璃',
              'elevatedCard': '突出玻璃',
              if (appearance == 'custom') 'custom': '保留自定义外观',
            },
            (v) {
              if (v != 'custom')
                editDialog(
                  (n) => n['style'] = v == 'inherit'
                      ? null
                      : styleJson(presets[v]!),
                );
            },
          ),
        ],
        if (dedicated)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('点击空白处可关闭'),
            value: props['barrierDismissible'] ?? true,
            onChanged: (v) => editEntry((p) => p['barrierDismissible'] = v),
          ),
        if (error != null)
          Text(
            '未应用：$error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const SizedBox(height: 12),
        LiquidGlassTheme(
          data: widget.theme == null
              ? LiquidGlassTheme.of(context)
              : glassTheme(widget.theme!),
          child: Builder(
            builder: (scope) => FilledButton.icon(
              key: const ValueKey('dialog-try'),
              focusNode: tryFocus,
              // Keep the trigger focusable while the route owns keyboard focus.
              onPressed: () => tryDialog(scope),
              icon: const Icon(Icons.play_arrow),
              label: const Text('试用弹窗'),
            ),
          ),
        ),
        if (result != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(result!, key: const ValueKey('dialog-last-result')),
          ),
        const SizedBox(height: 8),
        const Text('取消或关闭只结束本次试用；确认按钮返回设计的结果，不会自动操作业务数据。修改内容后请重新打开查看。'),
        TextButton(
          onPressed: widget.onAdvanced,
          child: const Text('更多布局与外观：高级模式'),
        ),
      ],
    );
  }
}
