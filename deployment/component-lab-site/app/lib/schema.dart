part of 'registry.dart';

const actionNames = [
  'none',
  'log',
  'dialog',
  'route',
  'close',
  'increment',
  'toggle',
  'focus',
  'setText',
];
const stateNames = [
  'default',
  'hovered',
  'pressed',
  'focused',
  'selected',
  'disabled',
];
const customControlKeys = {
  'foregroundColor',
  'backgroundColor',
  'overlayColor',
  'side',
  'textStyle',
  'iconSize',
  'padding',
  'minimumSize',
  'visualDensity',
  'tapTargetSize',
  'animationDuration',
};
const contentTypes = [
  'Text',
  'Icon',
  'GlassCard',
  'GlassSurface',
  'AnimatedGlassSurface',
  'GlassButton',
  'GlassIconButton',
  'GlassTextField',
  'GlassNavigationItem',
  'GlassTab',
  'GlassToolbar',
  'GlassMenu',
  'Row',
  'Column',
  'GlassBackdrop',
  'GlassGroup',
  'LiquidGlassTheme',
];

List<String> slotTypes(String slot) => switch (slot) {
  'dialog' => ['GlassDialog'],
  'menu' => ['MenuItemButton'],
  'icon' => ['Icon'],
  'trigger' || 'title' => ['Text', 'Icon', 'Row', 'Column'],
  'action' => ['GlassButton', 'GlassIconButton', 'GlassToolbar'],
  'root' => componentDefaults.keys.toList(),
  _ => contentTypes,
};

Map<String, String> schemaFor(String kind) {
  if (kind.startsWith('component:')) {
    final type = kind.substring(10);
    final defaults = componentDefaults[type]!;
    return {
      'type': 'enum:component',
      '_nodeId': 'string',
      for (final key in defaults.keys) key: componentField(type, key),
      if (type == 'GlassAppBar') 'bottomHeight': 'number',
    };
  }
  return switch (kind) {
    'scene' => {
      'version': 'number',
      'theme': 'theme',
      'modules': 'list:module',
    },
    'module' => {
      'id': 'string',
      'type': 'enum:component',
      'x': 'number',
      'y': 'number',
      'w': 'number',
      'h': 'number',
      'props': 'slot:root',
    },
    'theme' => {
      for (final k in themeDefaults().keys)
        k: switch (k) {
          'brightness' => 'enum:brightness',
          'accentColor' => 'color',
          'colorScheme' => 'scheme',
          'textTheme' => 'textTheme',
          'visualDensity' => 'enum:visualDensity',
          'tapTargetSize' => 'enum:tapTargetSize',
          'layout' => 'layout',
          'performance' => 'performance',
          'accessibility' => 'accessibility',
          'motion' => 'motion',
          'controlStyle' => 'control',
          _ => 'material',
        },
    },
    'layout' => {
      for (final k in (themeDefaults()['layout'] as Map).keys)
        k: k.toString().endsWith('Padding') ? 'insets' : 'number',
    },
    'performance' => {
      for (final e in (themeDefaults()['performance'] as Map).entries)
        e.key: e.key == 'quality'
            ? 'enum:quality'
            : e.value is bool
            ? 'bool'
            : 'number',
    },
    'accessibility' => {
      for (final k in (themeDefaults()['accessibility'] as Map).keys) k: 'bool',
    },
    'motion' || 'dialogMotion' || 'pageMotion' => {
      for (final k in motionDefaults().keys)
        if ((kind != 'pageMotion' ||
                [
                  'transition',
                  'duration',
                  'reverseDuration',
                  'curve',
                  'reverseCurve',
                ].contains(k)) &&
            (kind != 'dialogMotion' ||
                ![
                  'reverseDuration',
                  'pressDuration',
                  'hoverDuration',
                  'releaseDuration',
                  'surfaceDuration',
                  'interactionCurve',
                ].contains(k)))
          k: k == 'transition'
              ? 'enum:transition'
              : k.toLowerCase().contains('curve')
              ? 'enum:curve'
              : 'number',
    },
    'material' => {
      for (final k in styleJson(GlassPresets.card).keys)
        k: switch (k) {
          'blurEnabled' || 'noiseEnabled' => 'bool',
          'shape' => 'enum:shape',
          'backgroundGradient' || 'borderGradient' => 'gradient',
          'borderRadius' => 'radius',
          'shadowOffset' => 'offset',
          _ => k.endsWith('Color') ? 'color' : 'number',
        },
    },
    'control' || 'customControl' || 'customControlNoPadding' => {
      for (final k in controlDefaults().keys)
        if ((!kind.startsWith('customControl') ||
                customControlKeys.contains(k)) &&
            (kind != 'customControlNoPadding' || k != 'padding'))
          k: switch (k) {
            'visualDensity' => 'enum:visualDensity',
            'tapTargetSize' => 'enum:tapTargetSize',
            'animationDuration' => 'number',
            'side' => 'state:side',
            'textStyle' => 'state:textStyle',
            'shape' => 'state:controlShape',
            'padding' => 'state:insets',
            'minimumSize' || 'maximumSize' || 'fixedSize' => 'state:size',
            'mouseCursor' => 'state:enum:mouseCursor',
            _ => k.endsWith('Color') ? 'state:color' : 'state:number',
          },
    },
    'textStyle' => {
      'color': 'color',
      'foreground': 'paint',
      'backgroundColor': 'color',
      'fontFamily': 'enum:fontFamily',
      'fontSize': 'number',
      'fontWeight': 'enum:fontWeight',
      'fontStyle': 'enum:fontStyle',
      'letterSpacing': 'number',
      'wordSpacing': 'number',
      'height': 'number',
      'decoration': 'enum:textDecoration',
    },
    'paint' => {
      'color': 'color',
      'style': 'enum:paintStyle',
      'strokeWidth': 'number',
    },
    'side' => {'color': 'color', 'width': 'number'},
    'constraints' => {
      for (final k in ['minWidth', 'maxWidth', 'minHeight', 'maxHeight'])
        k: 'number',
    },
    'gradient' => {
      'type': 'enum:gradient',
      'colors': 'list:color',
      'stops': 'list:number',
      'begin': 'enum:alignment',
      'end': 'enum:alignment',
      'center': 'enum:alignment',
      'radius': 'number',
    },
    'scheme' => {
      for (final k in ['seedColor', 'primary', 'surface', 'onSurface'])
        k: 'color',
    },
    'textTheme' => {
      for (final k in [
        'bodyMedium',
        'labelLarge',
        'headlineSmall',
        'titleLarge',
      ])
        k: 'textStyle',
    },
    'route' => {'name': 'string', 'arguments': 'any'},
    'decoration' => {
      for (final k in [
        'hintText',
        'labelText',
        'helperText',
        'errorText',
        'prefixText',
        'suffixText',
      ])
        k: 'string',
      for (final k in ['prefixIcon', 'suffixIcon', 'prefix', 'suffix'])
        k: 'slot:icon',
      for (final k in ['filled', 'isDense', 'enabled']) k: 'bool',
      'fillColor': 'color',
      'contentPadding': 'insets',
      for (final k in [
        'labelStyle',
        'hintStyle',
        'helperStyle',
        'errorStyle',
        'floatingLabelStyle',
      ])
        k: 'textStyle',
      for (final k in [
        'border',
        'enabledBorder',
        'focusedBorder',
        'disabledBorder',
        'errorBorder',
        'focusedErrorBorder',
      ])
        k: 'inputBorder',
    },
    'inputBorder' => {'radius': 'radius', 'color': 'color', 'width': 'number'},
    'binding' => {'bind': 'string', 'default': 'bool'},
    'action' => {
      'action': 'enum:action',
      'key': 'string',
      'target': 'string',
      'text': 'string',
      'result': 'any',
      'builder': 'slot:content',
    },
    _ => {},
  };
}

String componentField(String type, String key) => switch (key) {
  'triggerKind' => 'enum:dialogTrigger',
  'triggerIcon' => 'enum:icon',
  'child' =>
    ['GlassButton', 'MenuItemButton'].contains(type)
        ? 'slot:trigger'
        : 'slot:content',
  'content' || 'bottom' || 'leading' || 'trailing' => 'slot:content',
  'title' => 'slot:title',
  'trigger' => 'slot:trigger',
  'icon' => type == 'Icon' ? 'enum:icon' : 'slot:icon',
  'leadingIcon' || 'trailingIcon' => 'slot:icon',
  'builder' => type == 'showGlassDialog' ? 'slot:dialog' : 'slot:content',
  'children' =>
    type == 'GlassToolbar' ? 'list:slot:action' : 'list:slot:content',
  'items' => 'list:slot:menu',
  'actions' => 'list:slot:action',
  'style' =>
    type == 'Text' || type == 'GlassTextField' ? 'textStyle' : 'material',
  'controlStyle' =>
    ['GlassButton', 'GlassIconButton'].contains(type)
        ? 'customControl'
        : 'control',
  'data' => 'theme',
  'decoration' => 'decoration',
  'constraints' => 'constraints',
  'motion' =>
    type == 'showGlassDialog'
        ? 'dialogMotion'
        : type == 'GlassPageRoute'
        ? 'pageMotion'
        : 'motion',
  'routeSettings' || 'settings' => 'route',
  'gradient' => 'gradient',
  'colors' => 'list:color',
  'padding' || 'margin' => 'insets',
  'alignment' =>
    ['Row', 'Column', 'GlassToolbar'].contains(type)
        ? 'enum:axis'
        : 'enum:alignment',
  'textAlign' => 'enum:textAlign',
  'duration' || 'spacing' => 'number',
  'textInputAction' => 'enum:textInputAction',
  'curve' => 'enum:curve',
  'clipBehavior' => 'enum:clipBehavior',
  'selected' => 'selected',
  'color' || 'fallbackColor' => 'color',
  _ =>
    key.startsWith('on')
        ? 'action'
        : switch (componentDefaults[type]![key]) {
            bool() => 'bool',
            num() => 'number',
            _ =>
              ['width', 'height', 'bottomHeight', 'maxLines'].contains(key)
                  ? 'number'
                  : 'string',
          },
};

List<String>? enumValues(String kind) => switch (kind) {
  'dialogTrigger' => ['button', 'iconButton', 'textLink', 'actionOnly'],
  'component' => componentDefaults.keys.toList(),
  'icon' => icons.keys.toList(),
  'axis' => MainAxisAlignment.values.map((v) => v.name).toList(),
  'textAlign' => TextAlign.values.map((v) => v.name).toList(),
  'gradient' => ['linear', 'radial'],
  'mouseCursor' => ['click', 'grab', 'basic'],
  'fontStyle' => ['normal', 'italic'],
  'fontFamily' => ['LabSans', 'Roboto'],
  'textDecoration' => ['none', 'underline', 'lineThrough'],
  'paintStyle' => ['fill', 'stroke'],
  'action' => actionNames,
  _ => enumOptions[kind],
};

String fieldLabel(String kind, String key) {
  if (kind == 'textStyle' && key == 'height') return '行高倍数';
  if (kind == 'gradient')
    return switch (key) {
      'type' => '渐变类型',
      'begin' => '渐变起点',
      'end' => '渐变终点',
      'center' => '渐变中心',
      'radius' => '渐变半径',
      _ => chineseLabel(key),
    };
  if ([
        'component:GlassSurface',
        'component:AnimatedGlassSurface',
      ].contains(kind) &&
      ['width', 'height'].contains(key))
    return key == 'width' ? '内部表面宽度' : '内部表面高度';
  if (['side', 'inputBorder'].contains(kind) && key == 'width') return '边框粗细';
  return chineseLabel(key);
}

dynamic valueAt(dynamic value, List<dynamic> path) {
  for (final key in path) {
    value = value is Map || value is List ? value[key] : null;
  }
  return value;
}

String kindAt(Json scene, List<dynamic> path) {
  String kind = 'scene';
  String? restricted;
  dynamic value = scene;
  for (final key in path) {
    if (kind.startsWith('state:') &&
        !(value is Map && value.keys.any(stateNames.contains)))
      kind = kind.substring(6);
    if (['slot:title', 'slot:trigger'].contains(kind)) restricted = kind;
    if (kind.startsWith('slot:') && value is Map)
      kind = 'component:${value['type'] ?? 'Text'}';
    if (kind == 'action' && value is Map && key == 'builder') {
      kind = value['action'] == 'dialog' ? 'slot:dialog' : 'slot:content';
    } else if (kind == 'module' && key == 'props') {
      kind = 'component:${value['type']}';
    } else if (kind.startsWith('list:')) {
      kind = kind.substring(5);
    } else if (kind.startsWith('state:') &&
        value is Map &&
        value.keys.any(stateNames.contains)) {
      kind = kind.substring(6);
    } else if (kind == 'selected' && value is Map) {
      kind = schemaFor('binding')[key] ?? 'unsupported';
    } else {
      final row = kind == 'component:Row' || kind == 'component:Column';
      kind = row && key == 'children' && restricted != null
          ? 'list:$restricted'
          : fieldsFor(kind, value is Map ? value : const {})[key] ??
                'unsupported';
    }
    value = value is Map || value is List ? value[key] : null;
  }
  return kind;
}

List<String> typesAt(Json scene, List<dynamic> path) {
  final kind = kindAt(scene, path);
  return slotTypes(kind.startsWith('slot:') ? kind.substring(5) : 'root');
}

Json switchComponent(Map old, String next, {String slot = 'root'}) {
  final before = old['type'] as String? ?? 'Text';
  final result = <String, dynamic>{
    'type': next,
    ...clone(componentDefaults[next]!),
  };
  if (old['_nodeId'] is String) result['_nodeId'] = old['_nodeId'];
  if (['trigger', 'title'].contains(slot) && ['Row', 'Column'].contains(next))
    result['children'] = [textNode(slot == 'trigger' ? '打开菜单' : '标题内容')];
  for (final k in [
    'child',
    'text',
    'label',
    'icon',
    'tooltip',
    'style',
    'padding',
    'margin',
    'focusNode',
    'autofocus',
    'enabled',
  ]) {
    if (old.containsKey(k) &&
        result.containsKey(k) &&
        componentField(before, k) == componentField(next, k))
      result[k] = old[k];
  }
  return result;
}

Json prepareScene(Json source) {
  final scene = clone(source);
  final ids = <String>{}, used = <String>{};
  var serial = 0;
  void scan(dynamic v, [int depth = 0]) {
    if (depth > 32) return;
    if (v is Map) {
      if (v['_nodeId'] is String) ids.add(v['_nodeId']);
      for (final child in v.values) {
        scan(child, depth + 1);
      }
    } else if (v is List) {
      for (final child in v) {
        scan(child, depth + 1);
      }
    }
  }

  scan(scene);
  void prepare(Map node) {
    final type = node['type'];
    if (!componentDefaults.containsKey(type)) return;
    if (node['_nodeId'] is! String || used.contains(node['_nodeId'])) {
      String id;
      do {
        id = 'part-${++serial}';
      } while (ids.contains(id));
      ids.add(id);
      node['_nodeId'] = id;
    }
    used.add(node['_nodeId']);
    void visit(dynamic value, String kind) {
      if (kind.startsWith('slot:') && value is Map)
        prepare(value);
      else if (kind.startsWith('list:') && value is List) {
        for (final item in value) {
          visit(item, kind.substring(5));
        }
      } else if (kind == 'action' && value is Map && value['builder'] is Map) {
        prepare(value['builder']);
      }
    }

    for (final e in node.entries) {
      visit(e.value, schemaFor('component:$type')[e.key] ?? 'unsupported');
    }
  }

  for (final module in scene['modules'] as List) {
    final node = <String, dynamic>{...module['props'], 'type': module['type']};
    prepare(node);
    node.remove('type');
    module['props'] = node;
  }
  return scene;
}

Map<String, dynamic> editorFields(Map data, String kind) {
  if (kind.startsWith('slot:')) kind = 'component:${data['type'] ?? 'Text'}';
  if (kind.startsWith('state:'))
    return data.keys.any(stateNames.contains)
        ? {for (final k in stateNames) k: data[k]}
        : editorFields(data, kind.substring(6));
  if (kind == 'selected') return editorFields(data, 'binding');
  final schema = fieldsFor(kind, data);
  if (schema.isEmpty) return Map<String, dynamic>.from(data);
  return {
    for (final k in schema.keys) k: data[k],
    for (final k in data.keys)
      if (!schema.containsKey(k)) k: data[k],
  };
}

Map<String, String> fieldsFor(String kind, Map data) {
  final fields = schemaFor(kind);
  if (kind == 'component:GlassTextField' &&
      data.containsKey('controller') &&
      data['controller'] == null)
    fields.remove('text');
  if (kind == 'component:GlassAppBar' && data['bottom'] == null)
    fields.remove('bottomHeight');
  if (kind == 'component:GlassButton' && data['padding'] != null)
    fields['controlStyle'] = 'customControlNoPadding';
  if (kind == 'textStyle' && data['foreground'] != null) fields.remove('color');
  if (kind == 'action') {
    final keys = switch (data['action']) {
      'dialog' || 'route' => ['action', 'builder'],
      'increment' || 'toggle' => ['action', 'key'],
      'focus' => ['action', 'target'],
      'setText' => ['action', 'target', 'text'],
      'close' => ['action', 'result'],
      _ => ['action'],
    };
    return {
      for (final k in keys)
        k: k == 'builder' && data['action'] == 'dialog'
            ? 'slot:dialog'
            : fields[k]!,
    };
  }
  if (kind == 'gradient')
    return {
      for (final k in [
        'type',
        'colors',
        'stops',
        if (data['type'] == 'radial') ...[
          'center',
          'radius',
        ] else ...[
          'begin',
          'end',
        ],
      ])
        k: fields[k]!,
    };
  return fields;
}

void validateConfig(
  dynamic value,
  String kind,
  String path, {
  dynamic previous,
  bool legacy = false,
  int depth = 0,
}) {
  final nonInteractive = ['slot:title', 'slot:trigger'].contains(kind);
  Never bad(String detail) => throw FormatException('$path：$detail');
  if (depth > 32) bad('嵌套过深');
  if (value == null) return;
  if (kind == 'any') return;
  if (kind.startsWith('slot:')) {
    if (value is String &&
        ['content', 'title', 'trigger'].contains(kind.substring(5)))
      return;
    if (value is! Map ||
        value['type'] is! String ||
        !slotTypes(kind.substring(5)).contains(value['type']))
      bad('此位置不支持该组件，请选择匹配的内容类型');
    kind = 'component:${value['type']}';
  }
  if (kind == 'selected') {
    if (value is bool) return;
    kind = 'binding';
  }
  if (kind == 'action') {
    if (value is String) {
      if (!actionNames.contains(value)) bad('未知动作');
      if (['focus', 'setText'].contains(value)) bad('此动作需要在配置中填写目标组件');
      return;
    }
    if (value is! Map || !actionNames.contains(value['action']))
      bad('动作需要有效的执行类型');
  }
  if (kind.startsWith('state:')) {
    if (value is Map && value.keys.any(stateNames.contains)) {
      for (final e in value.entries) {
        if (!stateNames.contains(e.key)) bad('未知控件状态');
        validateConfig(
          e.value,
          kind.substring(6),
          '$path.${e.key}',
          previous: previous is Map ? previous[e.key] : null,
          legacy: legacy,
          depth: depth + 1,
        );
      }
      return;
    }
    kind = kind.substring(6);
  }
  if (kind.startsWith('list:')) {
    if (value is! List || value.length > 100) bad('需要不超过100项的列表');
    for (var i = 0; i < value.length; i++)
      validateConfig(
        value[i],
        kind.substring(5),
        '$path[$i]',
        previous: previous is List && i < previous.length ? previous[i] : null,
        legacy: legacy,
        depth: depth + 1,
      );
    return;
  }
  if (kind.startsWith('enum:')) {
    if (value is! String ||
        !(enumValues(kind.substring(5)) ?? []).contains(value))
      bad('请选择有效选项');
    return;
  }
  if (kind == 'bool') {
    if (value is! bool) bad('需要开关值');
    return;
  }
  if (kind == 'string') {
    if (value is! String) bad('需要文字');
    return;
  }
  if (kind == 'number') {
    if (value is! num || !value.isFinite) bad('需要有限数字');
    return;
  }
  if (kind == 'color') {
    color(value);
    return;
  }
  if (kind == 'material' && value is String) {
    if (!presets.containsKey(value)) bad('未知材质预设');
    return;
  }
  if (kind == 'inputBorder' && value == 'none') return;
  if (kind == 'controlShape' && ['circle', 'stadium'].contains(value)) return;
  if (['insets', 'radius', 'size', 'offset', 'controlShape'].contains(kind)) {
    if (value is num && ['insets', 'radius', 'controlShape'].contains(kind)) {
      if (!value.isFinite || value < 0) bad('需要非负有限数');
      return;
    }
    final lengths = kind == 'insets'
        ? [2, 4]
        : kind == 'radius' || kind == 'controlShape'
        ? [4]
        : [2];
    if (value is! List ||
        !lengths.contains(value.length) ||
        value.any(
          (v) => v is! num || !v.isFinite || (kind != 'offset' && v < 0),
        ))
      bad('尺寸或间距格式无效');
    return;
  }
  if (value is! Map) bad('需要配置对象');
  final fields = fieldsFor(kind, value);
  if (fields.isEmpty) bad('不支持的参数');
  final merged = kind.startsWith('component:')
      ? {...componentDefaults[kind.substring(10)]!, ...value}
      : value;
  for (final e in merged.entries) {
    var fieldKind =
        nonInteractive &&
            ['component:Row', 'component:Column'].contains(kind) &&
            e.key == 'children'
        ? 'list:slot:trigger'
        : fields[e.key];
    if (kind == 'action' && e.key == 'builder')
      fieldKind = value['action'] == 'dialog' ? 'slot:dialog' : 'slot:content';
    if (fieldKind == null) {
      if (!value.containsKey(e.key) ||
          legacy ||
          previous is Map &&
              previous.containsKey(e.key) &&
              jsonEncode(previous[e.key]) == jsonEncode(e.value))
        continue;
      bad('“${chineseLabel(e.key.toString())}”不是此处可修改的参数');
    }
    validateConfig(
      e.value,
      fieldKind,
      '$path.${chineseLabel(e.key.toString())}',
      previous: previous is Map ? previous[e.key] : null,
      legacy: legacy,
      depth: depth + 1,
    );
    if (e.value is num) {
      final n = e.value as num, k = e.key.toString();
      if ((k.toLowerCase().contains('opacity') || k == 'intensity') &&
          (n < 0 || n > 1))
        bad('${chineseLabel(k)}需要0–1');
      if (![
            'x',
            'y',
            'highlightAngle',
            'letterSpacing',
            'wordSpacing',
          ].contains(k) &&
          n < 0)
        bad('${chineseLabel(k)}不能小于0');
      if ([
            'width',
            'height',
            'fontSize',
            'iconSize',
            'size',
            'dialogMaxWidth',
            'toolbarHeight',
            'maxLines',
            'radius',
          ].contains(k) &&
          n <= 0 &&
          !(['side', 'inputBorder'].contains(kind) && k == 'width' && n == 0))
        bad('${chineseLabel(k)}必须大于0');
      if (k == 'maxLines' && n != n.round()) bad('最大行数需要整数');
    }
  }
  if (kind.startsWith('component:')) {
    final type = kind.substring(10);
    for (final k in [
      'builder',
      if (type == 'GlassDialog') 'content',
      if (type == 'GlassMenu') 'trigger',
      if (type == 'GlassBackdrop') 'colors',
    ]) {
      if (fields.containsKey(k) && merged[k] == null)
        bad('${chineseLabel(k)}不能为空');
    }
    if (type == 'GlassBackdrop' && (merged['colors'] as List).length < 2)
      bad('背景至少需要两种颜色');
  }
  if (kind == 'constraints') {
    for (final axis in ['Width', 'Height'])
      if (number(value['min$axis']) >
          number(value['max$axis'], double.infinity))
        bad('最小尺寸不能大于最大尺寸');
  }
  if (kind == 'gradient') {
    if (value['colors'] is! List || (value['colors'] as List).length < 2)
      bad('渐变至少需要两种颜色');
    final stops = value['stops'];
    if (stops != null &&
        (stops.length != value['colors'].length ||
            stops.any((n) => n < 0 || n > 1)))
      bad('渐变位置需在0–1内并与配色数量一致');
    if (stops != null)
      for (var i = 1; i < stops.length; i++) {
        if (stops[i] < stops[i - 1]) bad('渐变位置必须递增');
      }
  }
  if (kind == 'binding' &&
      (value['bind'] is! String ||
          value['bind'].isEmpty ||
          value['default'] is! bool))
    bad('选中绑定需要变量名与布尔默认值');
  if (kind == 'action') {
    if (['focus', 'setText'].contains(value['action']) &&
        (value['target'] is! String || value['target'].isEmpty))
      bad('此动作需要目标组件标识');
  }
}
