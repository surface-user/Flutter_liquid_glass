import 'package:flutter/material.dart';
import 'editor_catalog.dart';
import 'labels.dart';
import 'parameter_input.dart';
import 'registry.dart';

class BasicInspector extends StatefulWidget {
  const BasicInspector({
    super.key,
    required this.module,
    required this.onApply,
    required this.onAdvanced,
  });
  final Json module;
  final String? Function(Json) onApply;
  final VoidCallback onAdvanced;
  @override
  State<BasicInspector> createState() => _BasicInspectorState();
}

class _BasicInspectorState extends State<BasicInspector> {
  static const appearanceOptions = {
    'subtle': '轻透',
    'card': '标准卡片',
    'elevatedCard': '浮起卡片',
  };
  String? error;
  Json get props => Map<String, dynamic>.from(widget.module['props'] as Map);
  String get type => widget.module['type'] as String;
  bool sameJson(dynamic a, dynamic b) {
    if (a is Map && b is Map) {
      return a.length == b.length &&
          a.entries.every(
            (entry) =>
                b.containsKey(entry.key) && sameJson(entry.value, b[entry.key]),
          );
    }
    if (a is List && b is List) {
      return a.length == b.length &&
          a.indexed.every((entry) => sameJson(entry.$2, b[entry.$1]));
    }
    return a == b;
  }

  String get appearance {
    final current = read(['props', 'style']);
    if (current == null) return 'inherit';
    for (final preset in appearanceOptions.keys) {
      if (sameJson(current, styleJson(presets[preset]!))) return preset;
    }
    return 'custom';
  }

  dynamic childAt(dynamic value, dynamic part) => value is Map
      ? value[part]
      : value is List && part is int && part >= 0 && part < value.length
      ? value[part]
      : null;

  dynamic read(List<dynamic> path) {
    dynamic value = widget.module;
    dynamic defaults = {'props': componentDefaults[type] ?? {}};
    for (var i = 0; i < path.length; i++) {
      final part = path[i];
      if (i > 0 &&
          value is Map &&
          componentDefaults.containsKey(value['type'])) {
        defaults = componentDefaults[value['type']];
      }
      final fallback = childAt(defaults, part);
      if (value is Map) {
        value = value.containsKey(part) ? value[part] : fallback;
      } else if (value is List && part is int && part < value.length) {
        value = value[part];
      } else {
        return null;
      }
      defaults = fallback;
    }
    return value;
  }

  String? change(List<dynamic> path, dynamic value) {
    final next = clone(widget.module);
    dynamic target = next;
    dynamic defaults = {'props': componentDefaults[type] ?? {}};
    for (var i = 0; i < path.length - 1; i++) {
      final part = path[i];
      if (i > 0 &&
          target is Map &&
          componentDefaults.containsKey(target['type'])) {
        defaults = componentDefaults[target['type']];
      }
      final fallback = childAt(defaults, part);
      if (target[part] == null) {
        final missing = target is Map && !target.containsKey(part);
        target[part] = missing && fallback is Map
            ? clone(Map<String, dynamic>.from(fallback))
            : missing && fallback is List
            ? clone({'value': fallback})['value']
            : fallback is Map &&
                  fallback['type'] == 'Text' &&
                  path.last == 'text'
            ? <String, dynamic>{'type': 'Text'}
            : <String, dynamic>{};
      }
      target = target[part];
      defaults = fallback;
    }
    target[path.last] = value;
    final result = widget.onApply(next);
    if (mounted) setState(() => error = result);
    return result;
  }

  bool textContent(dynamic value) => value is Map && value['type'] == 'Text';
  dynamic node(String field) => read(['props', field]);

  Widget section(String title) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
    ),
  );

  Widget input(
    String label,
    List<dynamic> path, {
    bool numeric = false,
    bool allowNull = false,
    dynamic fallback,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        ParameterInput(
          key: ValueKey('basic-${widget.module['id']}-${path.join('.')}'),
          value: read(path) ?? fallback,
          numeric: numeric,
          allowNull: allowNull,
          onApply: (value) => change(path, value),
        ),
      ],
    ),
  );

  Widget choice(
    String label,
    List<dynamic> path,
    Map<String, String> values, {
    String? fallback,
  }) {
    final current = read(path)?.toString() ?? fallback;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            key: ValueKey(
              'basic-${widget.module['id']}-${path.join('.')}-$current',
            ),
            initialValue: values.containsKey(current) ? current : null,
            isExpanded: true,
            isDense: false,
            itemHeight: null,
            decoration: const InputDecoration(),
            items: [
              for (final entry in values.entries)
                DropdownMenuItem(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 3,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) change(path, value);
            },
          ),
        ],
      ),
    );
  }

  Widget toggle(String label, List<dynamic> path, {bool fallback = false}) =>
      SwitchListTile(
        key: ValueKey('basic-${widget.module['id']}-${path.join('.')}'),
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: const TextStyle(fontSize: 12)),
        value: read(path) is bool ? read(path) as bool : fallback,
        onChanged: (value) => change(path, value),
      );

  Widget advancedNotice([String message = '这里包含自定义内容，普通编辑会保留原设置。']) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(message, style: const TextStyle(fontSize: 12, height: 1.5)),
      TextButton(onPressed: widget.onAdvanced, child: const Text('在高级模式查看')),
    ],
  );

  Widget labelContent(String field, String label) {
    final child = node(field);
    if (child == null)
      return input(label, ['props', field, 'text'], fallback: '');
    return textContent(child)
        ? input(label, ['props', field, 'text'], fallback: child['text'])
        : advancedNotice('此处使用了自定义图文组合，原内容保持不变。');
  }

  Widget action(String label, List<dynamic> path) {
    final value = read(path);
    final kind = value is Map ? value['action'] : value;
    final ordinaryDialog =
        ['GlassButton', 'GlassIconButton'].contains(type) &&
        path.length == 2 &&
        path[0] == 'props' &&
        path[1] == 'onPressed';
    final options = <String, String>{
      'none': type == 'GlassCard' ? '静态展示' : '无操作',
      'log': '记录事件',
      if (ordinaryDialog || kind == 'dialog')
        'dialog': ordinaryDialog ? '打开说明弹窗' : '保留原弹窗',
      if (!['none', 'log', 'dialog', null].contains(kind)) 'custom': '保留专用操作',
    };
    final selected = kind == null
        ? 'none'
        : options.containsKey(kind)
        ? kind as String
        : 'custom';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: DropdownButtonFormField<String>(
            key: ValueKey(
              'basic-${widget.module['id']}-${path.join('.')}-action-$selected',
            ),
            initialValue: selected,
            isExpanded: true,
            isDense: false,
            itemHeight: null,
            decoration: const InputDecoration(),
            items: [
              for (final e in options.entries)
                DropdownMenuItem(
                  value: e.key,
                  child: Text(
                    e.value,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 3,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
            ],
            onChanged: (next) {
              if (next == null || next == 'custom' || next == selected) return;
              change(
                path,
                next == 'dialog'
                    ? {
                        'action': 'dialog',
                        'builder': {
                          'type': 'GlassDialog',
                          ...clone(componentDefaults['GlassDialog']!),
                        },
                      }
                    : next,
              );
            },
          ),
        ),
        if (kind == 'dialog' && ordinaryDialog)
          const Text('已配置弹窗，将使用弹窗专用编辑。', style: TextStyle(fontSize: 11)),
        if (kind == 'dialog' && !ordinaryDialog) ...[
          const Text('已配置弹窗，内容编辑需进入高级模式。', style: TextStyle(fontSize: 11)),
          TextButton(
            onPressed: widget.onAdvanced,
            child: const Text('在高级模式编辑弹窗'),
          ),
        ],
        if (selected == 'custom') advancedNotice('专用操作已保留，普通模式不会重写它。'),
      ],
    );
  }

  List<Widget> itemList(String field, {required bool menu}) {
    final value = read(['props', field]);
    if (value is! List) return [advancedNotice()];
    return [
      for (var i = 0; i < value.length; i++) ...[
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '第${i + 1}项',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        if (value[i] is Map &&
            textContent(value[i]['child']) &&
            (menu
                ? value[i]['type'] == 'MenuItemButton'
                : value[i]['type'] == 'GlassButton')) ...[
          input('第${i + 1}项文字', ['props', field, i, 'child', 'text']),
          action('第${i + 1}项操作', ['props', field, i, 'onPressed']),
        ] else if (!menu &&
            value[i] is Map &&
            value[i]['type'] == 'GlassIconButton') ...[
          choice(
            '第${i + 1}项图标',
            ['props', field, i, 'icon', 'icon'],
            {for (final key in icons.keys) key: chineseLabel(key)},
          ),
          input('第${i + 1}项提示', ['props', field, i, 'tooltip']),
          action('第${i + 1}项操作', ['props', field, i, 'onPressed']),
        ] else
          advancedNotice('此条目是自定义内容，移动和文字设置不会自动改写它。'),
        Wrap(
          children: [
            if (i > 0)
              TextButton(
                key: ValueKey('basic-${widget.module['id']}-$field-$i-up'),
                onPressed: () {
                  final next = List<dynamic>.from(value);
                  final item = next.removeAt(i);
                  next.insert(i - 1, item);
                  change(['props', field], next);
                },
                child: const Text('上移'),
              ),
            TextButton(
              key: ValueKey('basic-${widget.module['id']}-$field-$i-remove'),
              onPressed: () {
                final next = List<dynamic>.from(value)..removeAt(i);
                change(['props', field], next);
              },
              child: const Text('移除此项'),
            ),
          ],
        ),
        const Divider(),
      ],
      TextButton.icon(
        key: ValueKey('basic-${widget.module['id']}-$field-add'),
        onPressed: () => change(
          ['props', field],
          [
            ...value,
            {
              'type': menu ? 'MenuItemButton' : 'GlassButton',
              'child': textNode(menu ? '新菜单项' : '新操作'),
              'onPressed': 'log',
            },
          ],
        ),
        icon: const Icon(Icons.add),
        label: Text(menu ? '添加菜单项' : '添加操作'),
      ),
    ];
  }

  List<Widget> contentFields() => switch (type) {
    'Text' => [
      input('文字内容', ['props', 'text']),
      input(
        '字号',
        ['props', 'style', 'fontSize'],
        numeric: true,
        allowNull: true,
      ),
      choice(
        '文字对齐',
        ['props', 'textAlign'],
        const {'start': '起始侧', 'center': '居中', 'end': '末尾侧', 'justify': '两端对齐'},
        fallback: 'start',
      ),
    ],
    'Icon' => [
      choice(
        '图案',
        ['props', 'icon'],
        {for (final key in icons.keys) key: chineseLabel(key)},
        fallback: 'sparkles',
      ),
      input('图形大小', ['props', 'size'], numeric: true, allowNull: true),
    ],
    'GlassCard' || 'GlassButton' => [
      labelContent('child', type == 'GlassCard' ? '卡片文字' : '按钮文字'),
      section('行为'),
      action(type == 'GlassCard' ? '整卡操作' : '点击操作', [
        'props',
        type == 'GlassCard' ? 'onTap' : 'onPressed',
      ]),
    ],
    'GlassIconButton' => [
      if (node('icon') is Map && node('icon')['type'] == 'Icon')
        choice(
          '按钮图标',
          ['props', 'icon', 'icon'],
          {for (final key in icons.keys) key: chineseLabel(key)},
        )
      else
        advancedNotice(),
      input('提示文字', ['props', 'tooltip']),
      section('行为'),
      action('点击操作', ['props', 'onPressed']),
    ],
    'GlassTextField' => [
      if (props.containsKey('controller') && props['controller'] == null)
        advancedNotice('此输入使用了独立的运行状态，普通模式保留原设置。')
      else
        input('设计初始文字', ['props', 'text']),
      input('输入提示', ['props', 'decoration', 'hintText'], allowNull: true),
      input('字段标签', ['props', 'decoration', 'labelText'], allowNull: true),
      input('辅助说明', ['props', 'decoration', 'helperText'], allowNull: true),
      input('错误提示', ['props', 'decoration', 'errorText'], allowNull: true),
      toggle('允许输入', ['props', 'enabled'], fallback: true),
      toggle('只读', ['props', 'readOnly']),
      const Text('运行时的输入草稿不会自动覆盖这里的设计初始文字。', style: TextStyle(fontSize: 11)),
    ],
    'GlassMenu' => [
      labelContent('trigger', '入口文字'),
      toggle('允许打开', ['props', 'enabled'], fallback: true),
      section('菜单项'),
      ...itemList('items', menu: true),
    ],
    'GlassNavigationItem' || 'GlassTab' => [
      input(type == 'GlassTab' ? '标签文字' : '导航文字', ['props', 'label']),
      if (props['selected'] is! Map)
        toggle('设计中已选中', ['props', 'selected'])
      else
        advancedNotice('选中状态使用了专用绑定，普通模式保留它。'),
      section('行为'),
      action('点击操作', [
        'props',
        type == 'GlassTab' ? 'onSelected' : 'onPressed',
      ]),
      if (type == 'GlassTab') ...[
        action('关闭按钮操作', ['props', 'onClose']),
        const Text('关闭回调不会自动删除这个标签或管理页面。', style: TextStyle(fontSize: 11)),
      ],
    ],
    'GlassToolbar' => [
      section('操作项'),
      ...itemList('children', menu: false),
      input('操作间距', ['props', 'spacing'], numeric: true, allowNull: true),
      choice(
        '排列对齐',
        ['props', 'alignment'],
        const {
          'start': '起始侧',
          'center': '居中',
          'end': '末尾侧',
          'spaceBetween': '两端分散',
          'spaceAround': '两侧留白',
          'spaceEvenly': '均匀分布',
        },
        fallback: 'start',
      ),
    ],
    'GlassAppBar' => [
      labelContent('title', '顶栏标题'),
      input('标题栏高度', ['props', 'toolbarHeight'], numeric: true, fallback: 56),
      section('顶栏操作'),
      ...itemList('actions', menu: false),
    ],
    'Row' || 'Column' => [
      input('内容间距', ['props', 'spacing'], numeric: true, fallback: 12),
      choice(
        '排列对齐',
        ['props', 'alignment'],
        const {
          'start': '起始侧',
          'center': '居中',
          'end': '末尾侧',
          'spaceBetween': '两端分散',
          'spaceAround': '两侧留白',
          'spaceEvenly': '均匀分布',
        },
        fallback: 'center',
      ),
      advancedNotice('现有排列和内容会完整保留。添加或调整自定义子内容，请进入高级模式。'),
    ],
    'showGlassDialog' ||
    'GlassDialog' => [advancedNotice('弹窗内容请使用弹窗专用编辑入口调整。')],
    _ => [advancedNotice('此内容使用高级设置。普通模式会保留原内容与效果。')],
  };

  @override
  Widget build(BuildContext context) {
    final entry = basicEntryFor(type);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '未应用：$error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (entry != null)
          Text(
            entry.description,
            style: const TextStyle(fontSize: 11, height: 1.5),
          ),
        section('内容与用途'),
        ...contentFields(),
        if ([
          'GlassCard',
          'GlassButton',
          'GlassIconButton',
          'GlassAppBar',
        ].contains(type)) ...[
          section('外观'),
          const Text('材质方案', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              key: ValueKey(
                'basic-${widget.module['id']}-appearance-$appearance',
              ),
              initialValue: appearance,
              isExpanded: true,
              isDense: false,
              itemHeight: null,
              decoration: const InputDecoration(),
              items: [
                const DropdownMenuItem(
                  value: 'inherit',
                  child: Text(
                    '跟随整体外观',
                    style: TextStyle(fontSize: 12),
                    maxLines: 3,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
                const DropdownMenuItem(
                  value: 'custom',
                  enabled: false,
                  child: Text(
                    '自定义外观',
                    style: TextStyle(fontSize: 12),
                    maxLines: 3,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
                for (final entry in appearanceOptions.entries)
                  DropdownMenuItem(
                    value: entry.key,
                    child: Text(
                      entry.value,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 3,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null && value != 'custom')
                  change([
                    'props',
                    'style',
                  ], value == 'inherit' ? null : styleJson(presets[value]!));
              },
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: widget.onAdvanced,
          icon: const Icon(Icons.tune),
          label: const Text('更多高级设置'),
        ),
      ],
    );
  }
}
