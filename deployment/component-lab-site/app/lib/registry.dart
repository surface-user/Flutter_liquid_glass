import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';
import 'labels.dart';
part 'schema.dart';

typedef Json = Map<String, dynamic>;
Json clone(Json value) => jsonDecode(jsonEncode(value)) as Json;
const icons = <String, IconData>{
  'sparkles': Icons.auto_awesome,
  'add': Icons.add,
  'search': Icons.search,
  'close': Icons.close,
  'folder': Icons.folder_outlined,
  'file': Icons.description_outlined,
  'heart': Icons.favorite_outline,
  'settings': Icons.tune,
  'home': Icons.home_outlined,
  'info': Icons.info_outline,
  'arrow': Icons.arrow_forward,
  'check': Icons.check,
};
const enumOptions = <String, List<String>>{
  'brightness': ['light', 'dark'],
  'quality': ['low', 'balanced', 'adaptive', 'high'],
  'shape': ['rectangle', 'circle'],
  'clipBehavior': ['none', 'hardEdge', 'antiAlias', 'antiAliasWithSaveLayer'],
  'transition': ['fade', 'fadeSlide', 'scaleFade', 'sharedAxis', 'none'],
  'alignment': [
    'topLeft',
    'topCenter',
    'topRight',
    'centerLeft',
    'center',
    'centerRight',
    'bottomLeft',
    'bottomCenter',
    'bottomRight',
  ],
  'visualDensity': ['standard', 'comfortable', 'compact'],
  'tapTargetSize': ['padded', 'shrinkWrap'],
  'curve': [
    'linear',
    'easeIn',
    'easeOut',
    'easeInOut',
    'easeOutCubic',
    'easeInCubic',
  ],
  'reverseCurve': [
    'linear',
    'easeIn',
    'easeOut',
    'easeInOut',
    'easeOutCubic',
    'easeInCubic',
  ],
  'interactionCurve': [
    'linear',
    'easeIn',
    'easeOut',
    'easeInOut',
    'easeOutCubic',
    'easeInCubic',
  ],
  'textInputAction': ['none', 'done', 'search', 'next', 'go', 'send'],
  'fontWeight': [
    'normal',
    'bold',
    'w300',
    'w400',
    'w500',
    'w600',
    'w700',
    'w800',
  ],
};

Json styleJson(GlassStyle s) => {
  'blurSigmaX': s.blurSigmaX,
  'blurSigmaY': s.blurSigmaY,
  'blurEnabled': s.blurEnabled,
  'tintColor': hex(s.tintColor),
  'tintOpacity': s.tintOpacity,
  'backgroundGradient': null,
  'saturation': s.saturation,
  'contrast': s.contrast,
  'borderColor': hex(s.borderColor),
  'borderOpacity': s.borderOpacity,
  'borderWidth': s.borderWidth,
  'borderGradient': null,
  'borderRadius': s.borderRadius.topLeft.x,
  'shape': s.shape.name,
  'highlightColor': hex(s.highlightColor),
  'highlightOpacity': s.highlightOpacity,
  'highlightAngle': s.highlightAngle,
  'shadowColor': hex(s.shadowColor),
  'shadowOpacity': s.shadowOpacity,
  'shadowBlurRadius': s.shadowBlurRadius,
  'shadowOffset': [s.shadowOffset.dx, s.shadowOffset.dy],
  'noiseOpacity': s.noiseOpacity,
  'noiseEnabled': s.noiseEnabled,
};
final presets = {
  'subtle': GlassPresets.subtle,
  'card': GlassPresets.card,
  'elevatedCard': GlassPresets.elevatedCard,
  'button': GlassPresets.button,
  'appBar': GlassPresets.appBar,
  'dialog': GlassPresets.dialog,
  'selected': GlassPresets.selected,
};
Json textNode(String text) => {'type': 'Text', 'text': text};
Json iconNode([String icon = 'sparkles']) => {
  'type': 'Icon',
  'icon': icon,
  'size': null,
};
Json controlDefaults() => {
  'foregroundColor': null,
  'backgroundColor': null,
  'overlayColor': null,
  'side': null,
  'textStyle': null,
  'iconSize': null,
  'padding': null,
  'minimumSize': null,
  'shape': null,
  'iconColor': null,
  'fixedSize': null,
  'maximumSize': null,
  'elevation': null,
  'shadowColor': null,
  'surfaceTintColor': null,
  'mouseCursor': null,
  'visualDensity': null,
  'tapTargetSize': null,
  'animationDuration': null,
};
Json motionDefaults() => {
  'transition': 'fadeSlide',
  'duration': 280,
  'reverseDuration': 220,
  'curve': 'easeOutCubic',
  'reverseCurve': 'easeInCubic',
  'pressDuration': 90,
  'hoverDuration': 160,
  'releaseDuration': 180,
  'surfaceDuration': 240,
  'interactionCurve': 'easeOutCubic',
};
Json themeDefaults() => {
  'brightness': 'light',
  'accentColor': '#4263EB',
  'colorScheme': null,
  'textTheme': {
    'bodyMedium': {},
    'labelLarge': {},
    'headlineSmall': {},
    'titleLarge': {},
  },
  'visualDensity': 'standard',
  'tapTargetSize': 'padded',
  'layout': {
    'cardPadding': 20,
    'buttonPadding': [20, 12],
    'iconButtonPadding': 12,
    'dialogPadding': 24,
    'dialogMaxWidth': 480,
    'titleSpacing': 16,
    'actionSpacing': 24,
    'actionRunSpacing': 12,
    'iconSize': null,
    'appBarTitleSpacing': null,
  },
  'performance': {
    'quality': 'adaptive',
    'blurEnabled': true,
    'maxBlurSigma': 20,
    'groupBackdropFilters': true,
    'enableNoise': false,
    'enableShadows': true,
    'enableAnimations': true,
  },
  'accessibility': {
    'highContrast': false,
    'reduceMotion': false,
    'reduceTransparency': false,
  },
  'motion': motionDefaults(),
  'controlStyle': controlDefaults(),
  'defaultStyle': styleJson(GlassPresets.card),
  'cardStyle': styleJson(GlassPresets.card),
  'buttonStyle': styleJson(GlassPresets.button),
  'dialogStyle': styleJson(GlassPresets.dialog),
  'appBarStyle': styleJson(GlassPresets.appBar),
};
final componentDefaults = <String, Json>{
  'GlassCard': {
    'child': textNode('把灵感放进玻璃里'),
    'style': null,
    'padding': null,
    'margin': null,
    'onTap': 'log',
    'focusNode': null,
    'autofocus': false,
  },
  'GlassButton': {
    'child': textNode('试试点击我'),
    'onPressed': 'log',
    'style': null,
    'controlStyle': null,
    'focusNode': null,
    'padding': null,
    'autofocus': false,
  },
  'GlassIconButton': {
    'icon': iconNode('heart'),
    'onPressed': 'log',
    'tooltip': '收藏',
    'style': null,
    'controlStyle': null,
    'focusNode': null,
    'autofocus': false,
  },
  'GlassSurface': {
    'child': textNode('原生渲染 · 玻璃表面'),
    'width': null,
    'height': null,
    'constraints': null,
    'padding': 20,
    'margin': null,
    'alignment': 'center',
    'style': null,
    'fallbackColor': null,
    'clipBehavior': 'antiAlias',
    'enabled': true,
  },
  'AnimatedGlassSurface': {
    'child': textNode('改动样式，观察过渡'),
    'style': null,
    'duration': null,
    'curve': null,
    'width': null,
    'height': null,
    'constraints': null,
    'padding': 20,
    'margin': null,
    'alignment': 'center',
    'fallbackColor': null,
    'clipBehavior': 'antiAlias',
    'enabled': true,
  },
  'GlassTextField': {
    'controller': '@self',
    'focusNode': '@self',
    'text': '',
    'enabled': true,
    'readOnly': false,
    'autofocus': false,
    'decoration': {
      'hintText': '搜索灵感…',
      'labelText': null,
      'helperText': null,
      'errorText': null,
      'prefixIcon': iconNode('search'),
      'suffixIcon': null,
      'filled': true,
      'fillColor': null,
      'isDense': false,
      'contentPadding': null,
      'border': null,
    },
    'style': {},
    'onChanged': 'log',
    'onSubmitted': 'log',
    'textInputAction': 'search',
  },
  'GlassNavigationItem': {
    'label': '灵感资料库',
    'leading': iconNode('folder'),
    'trailing': null,
    'selected': false,
    'indent': 0,
    'onPressed': 'log',
    'focusNode': null,
    'controlStyle': null,
  },
  'GlassTab': {
    'label': '未命名画布',
    'leading': iconNode('file'),
    'selected': true,
    'onSelected': 'log',
    'onClose': 'log',
    'focusNode': null,
    'controlStyle': null,
  },
  'GlassToolbar': {
    'children': [
      {'type': 'GlassButton', 'child': textNode('新建'), 'onPressed': 'log'},
      {
        'type': 'GlassIconButton',
        'icon': iconNode('settings'),
        'tooltip': '设置',
        'onPressed': 'log',
      },
    ],
    'spacing': null,
    'alignment': 'start',
  },
  'GlassMenu': {
    'trigger': textNode('打开菜单'),
    'items': [
      {
        'type': 'MenuItemButton',
        'child': textNode('记录一次调用'),
        'onPressed': 'log',
      },
      {
        'type': 'MenuItemButton',
        'child': textNode('打开弹窗'),
        'onPressed': 'dialog',
      },
    ],
    'enabled': true,
    'focusNode': '@self',
    'onOpen': 'log',
    'onClose': 'log',
    'controlStyle': null,
  },
  'GlassAppBar': {
    'title': textNode('你的工作空间'),
    'leading': null,
    'actions': [
      {
        'type': 'GlassIconButton',
        'icon': iconNode('settings'),
        'tooltip': '设置',
        'onPressed': 'log',
      },
    ],
    'style': null,
    'bottom': null,
    'toolbarHeight': 56,
    'automaticallyImplyLeading': false,
  },
  'GlassDialog': {
    'title': textNode('一点新的想法'),
    'content': textNode('内容、动作、几何与材质，都由你决定。'),
    'actions': [
      {'type': 'GlassButton', 'child': textNode('知道了'), 'onPressed': 'close'},
    ],
    'style': null,
    'semanticLabel': '测试弹窗',
    'padding': null,
    'constraints': null,
  },
  'showGlassDialog': {
    'child': textNode('打开玻璃弹窗'),
    'triggerKind': 'button',
    'triggerIcon': 'info',
    'builder': {
      'type': 'GlassDialog',
      'title': textNode('你好，玻璃世界'),
      'content': textNode('这是由真实 Flutter 路由打开的弹窗'),
      'actions': [
        {'type': 'GlassButton', 'child': textNode('关闭'), 'onPressed': 'close'},
      ],
    },
    'barrierDismissible': true,
    'useRootNavigator': true,
    'routeSettings': {'name': 'lab-dialog'},
    'motion': {
      for (final e in motionDefaults().entries)
        if (['transition', 'duration', 'curve', 'reverseCurve'].contains(e.key))
          e.key: e.value,
    },
  },
  'GlassPageRoute': {
    'child': textNode('打开示例页面'),
    'builder': {'type': 'GlassCard', 'child': textNode('新的页面，新的可能。')},
    'motion': {
      for (final e in motionDefaults().entries)
        if ([
          'transition',
          'duration',
          'reverseDuration',
          'curve',
          'reverseCurve',
        ].contains(e.key))
          e.key: e.value,
    },
    'reduceMotion': false,
    'settings': {'name': 'lab-page'},
    'fullscreenDialog': false,
  },
  'GlassBackdrop': {
    'child': textNode('静态背景，保持低开销'),
    'colors': ['#7A9FFF', '#CFA5EE', '#70D8CF'],
    'gradient': null,
    'intensity': 1.0,
    'animate': false,
  },
  'GlassGroup': {
    'overlapping': false,
    'child': {
      'type': 'Row',
      'children': [
        {'type': 'GlassCard', 'child': textNode('分组 A')},
        {'type': 'GlassCard', 'child': textNode('分组 B')},
      ],
    },
  },
  'LiquidGlassTheme': {
    'merge': true,
    'data': {'visualDensity': 'compact', 'tapTargetSize': 'shrinkWrap'},
    'child': {
      'type': 'GlassButton',
      'child': textNode('局部主题'),
      'onPressed': 'log',
    },
  },
  'Text': {
    'text': '写下你的想法',
    'style': {'fontSize': 18, 'fontWeight': 'w500'},
    'maxLines': null,
    'textAlign': 'start',
  },
  'Icon': {'icon': 'sparkles', 'size': 28.0, 'color': null},
  'Column': {
    'children': [
      textNode('组合你的组件'),
      {'type': 'GlassButton', 'child': textNode('开始'), 'onPressed': 'log'},
    ],
    'spacing': 12.0,
    'alignment': 'center',
  },
  'Row': {
    'children': [iconNode(), textNode('自由组合')],
    'spacing': 12.0,
    'alignment': 'center',
  },
  'MenuItemButton': {
    'child': textNode('菜单动作'),
    'onPressed': 'log',
    'leadingIcon': null,
    'trailingIcon': null,
    'closeOnActivate': true,
  },
};

Color color(dynamic value, [Color fallback = Colors.white]) {
  if (value == null) return fallback;
  if (value is int) return Color(value);
  final v = value.toString().replaceFirst('#', '');
  if (!RegExp(r'^(?:[a-fA-F0-9]{6}|[a-fA-F0-9]{8})$').hasMatch(v))
    throw const FormatException('颜色需为 #RRGGBB 或 #AARRGGBB');
  return Color(int.parse(v.length == 6 ? 'ff$v' : v, radix: 16));
}

String hex(Color c) =>
    '#${c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
double number(dynamic x, [double fallback = 0]) {
  if (x == null) return fallback;
  if (x is! num || !x.isFinite) throw const FormatException('请输入有限数字');
  return x.toDouble();
}

double? optionalNumber(dynamic x) => x == null ? null : number(x);
Duration duration(dynamic x, [int fallback = 160]) =>
    Duration(milliseconds: number(x, fallback.toDouble()).round());
EdgeInsets? insets(dynamic x) {
  if (x == null) return null;
  if (x is num) return EdgeInsets.all(number(x));
  final a = (x as List).map((v) => number(v)).toList();
  if (a.length == 2)
    return EdgeInsets.symmetric(horizontal: a[0], vertical: a[1]);
  if (a.length != 4) throw const FormatException('间距为数字、[水平,垂直]或[左,上,右,下]');
  return EdgeInsets.fromLTRB(a[0], a[1], a[2], a[3]);
}

BorderRadius radius(dynamic x) {
  if (x is List && x.length == 4)
    return BorderRadius.only(
      topLeft: Radius.circular(number(x[0])),
      topRight: Radius.circular(number(x[1])),
      bottomRight: Radius.circular(number(x[2])),
      bottomLeft: Radius.circular(number(x[3])),
    );
  return BorderRadius.circular(number(x, 24));
}

Alignment alignment(dynamic x) => switch (x) {
  'topLeft' => Alignment.topLeft,
  'topCenter' => Alignment.topCenter,
  'topRight' => Alignment.topRight,
  'centerLeft' => Alignment.centerLeft,
  'centerRight' => Alignment.centerRight,
  'bottomLeft' => Alignment.bottomLeft,
  'bottomCenter' => Alignment.bottomCenter,
  'bottomRight' => Alignment.bottomRight,
  _ => Alignment.center,
};
Gradient? gradient(dynamic x) {
  if (x == null) return null;
  final m = x as Map;
  final colors = (m['colors'] as List).map((v) => color(v)).toList();
  if (colors.length < 2) throw const FormatException('渐变至少需要两个颜色');
  final stops = (m['stops'] as List?)?.map((v) => number(v)).toList();
  if (stops != null && stops.length != colors.length)
    throw const FormatException('渐变 stops 必须与 colors 数量相同');
  return m['type'] == 'radial'
      ? RadialGradient(
          colors: colors,
          stops: stops,
          center: alignment(m['center']),
          radius: number(m['radius'], .5),
        )
      : LinearGradient(
          colors: colors,
          stops: stops,
          begin: alignment(m['begin'] ?? 'topLeft'),
          end: alignment(m['end'] ?? 'bottomRight'),
        );
}

GlassStyle glassStyle(dynamic x, [GlassStyle base = GlassPresets.card]) {
  if (x == null) return base;
  if (x is String) return presets[x] ?? (throw FormatException('未知预设 $x'));
  final m = x as Map;
  double n(String k, double v) => number(m[k], v);
  return base.copyWith(
    blurSigmaX: n('blurSigmaX', base.blurSigmaX),
    blurSigmaY: n('blurSigmaY', base.blurSigmaY),
    blurEnabled: m['blurEnabled'] ?? base.blurEnabled,
    tintColor: color(m['tintColor'], base.tintColor),
    tintOpacity: n('tintOpacity', base.tintOpacity),
    backgroundGradient: m.containsKey('backgroundGradient')
        ? gradient(m['backgroundGradient'])
        : base.backgroundGradient,
    saturation: n('saturation', base.saturation),
    contrast: n('contrast', base.contrast),
    borderColor: color(m['borderColor'], base.borderColor),
    borderOpacity: n('borderOpacity', base.borderOpacity),
    borderWidth: n('borderWidth', base.borderWidth),
    borderGradient: m.containsKey('borderGradient')
        ? gradient(m['borderGradient'])
        : base.borderGradient,
    borderRadius: m.containsKey('borderRadius')
        ? radius(m['borderRadius'])
        : base.borderRadius,
    shape: m.containsKey('shape')
        ? (m['shape'] == 'circle' ? BoxShape.circle : BoxShape.rectangle)
        : base.shape,
    highlightColor: color(m['highlightColor'], base.highlightColor),
    highlightOpacity: n('highlightOpacity', base.highlightOpacity),
    highlightAngle: n('highlightAngle', base.highlightAngle),
    shadowColor: color(m['shadowColor'], base.shadowColor),
    shadowOpacity: n('shadowOpacity', base.shadowOpacity),
    shadowBlurRadius: n('shadowBlurRadius', base.shadowBlurRadius),
    shadowOffset: m['shadowOffset'] == null
        ? base.shadowOffset
        : Offset(number(m['shadowOffset'][0]), number(m['shadowOffset'][1])),
    noiseOpacity: n('noiseOpacity', base.noiseOpacity),
    noiseEnabled: m['noiseEnabled'] ?? base.noiseEnabled,
  );
}

BoxConstraints? constraints(dynamic x) => x == null
    ? null
    : BoxConstraints(
        minWidth: number(x['minWidth']),
        maxWidth: number(x['maxWidth'], double.infinity),
        minHeight: number(x['minHeight']),
        maxHeight: number(x['maxHeight'], double.infinity),
      );
Curve curve(dynamic x) => switch (x) {
  'linear' => Curves.linear,
  'easeIn' => Curves.easeIn,
  'easeOut' => Curves.easeOut,
  'easeInOut' => Curves.easeInOut,
  'easeInCubic' => Curves.easeInCubic,
  _ => Curves.easeOutCubic,
};
VisualDensity density(dynamic x) => switch (x) {
  'compact' => VisualDensity.compact,
  'comfortable' => VisualDensity.comfortable,
  _ => VisualDensity.standard,
};
MaterialTapTargetSize target(dynamic x) => x == 'shrinkWrap'
    ? MaterialTapTargetSize.shrinkWrap
    : MaterialTapTargetSize.padded;
GlassMotionSpec motion(dynamic x) {
  final m = x as Map? ?? {};
  return GlassMotionSpec(
    transition: GlassTransition.values.firstWhere(
      (v) => v.name == (m['transition'] ?? 'fadeSlide'),
    ),
    duration: duration(m['duration'], 280),
    reverseDuration: duration(m['reverseDuration'], 220),
    curve: curve(m['curve']),
    reverseCurve: curve(m['reverseCurve'] ?? 'easeInCubic'),
    pressDuration: duration(m['pressDuration'], 90),
    hoverDuration: duration(m['hoverDuration'], 160),
    releaseDuration: duration(m['releaseDuration'], 180),
    surfaceDuration: duration(m['surfaceDuration'], 240),
    interactionCurve: curve(m['interactionCurve']),
  );
}

TextStyle? textStyle(dynamic x) {
  if (x == null) return null;
  final m = x as Map;
  final weights = {
    'normal': FontWeight.normal,
    'bold': FontWeight.bold,
    'w300': FontWeight.w300,
    'w400': FontWeight.w400,
    'w500': FontWeight.w500,
    'w600': FontWeight.w600,
    'w700': FontWeight.w700,
    'w800': FontWeight.w800,
  };
  return TextStyle(
    color: m['foreground'] != null
        ? null
        : m['color'] == null
        ? null
        : color(m['color']),
    foreground: m['foreground'] == null
        ? null
        : (Paint()
            ..color = color(m['foreground']['color'])
            ..style = (m['foreground']['style'] == 'stroke'
                ? PaintingStyle.stroke
                : PaintingStyle.fill)
            ..strokeWidth = number(m['foreground']['strokeWidth'], 1)),
    backgroundColor: m['backgroundColor'] == null
        ? null
        : color(m['backgroundColor']),
    fontFamily: m['fontFamily'],
    fontSize: optionalNumber(m['fontSize']),
    fontWeight: weights[m['fontWeight']],
    fontStyle: m['fontStyle'] == null
        ? null
        : m['fontStyle'] == 'italic'
        ? FontStyle.italic
        : FontStyle.normal,
    letterSpacing: optionalNumber(m['letterSpacing']),
    wordSpacing: optionalNumber(m['wordSpacing']),
    height: optionalNumber(m['height']),
    decoration: m['decoration'] == 'underline'
        ? TextDecoration.underline
        : m['decoration'] == 'lineThrough'
        ? TextDecoration.lineThrough
        : m['decoration'] == 'none'
        ? TextDecoration.none
        : null,
  );
}

BorderSide? side(dynamic x) => x == null
    ? null
    : BorderSide(color: color(x['color']), width: number(x['width'], 1));
Size? size(dynamic x) => x == null ? null : Size(number(x[0]), number(x[1]));
WidgetStateProperty<T?>? state<T>(dynamic x, T? Function(dynamic) convert) {
  if (x == null) return null;
  return WidgetStateProperty.resolveWith((states) {
    if (x is Map &&
        x.keys.any(
          (k) => [
            'default',
            'hovered',
            'pressed',
            'focused',
            'selected',
            'disabled',
          ].contains(k),
        )) {
      for (final s in [
        WidgetState.disabled,
        WidgetState.pressed,
        WidgetState.focused,
        WidgetState.hovered,
        WidgetState.selected,
      ]) {
        if (states.contains(s) && x.containsKey(s.name))
          return x[s.name] == null ? null : convert(x[s.name]);
      }
      return x['default'] == null ? null : convert(x['default']);
    }
    return convert(x);
  });
}

ButtonStyle? control(dynamic x, {bool custom = false}) {
  if (x == null) return null;
  final m = custom
      ? Map.fromEntries(
          (x as Map).entries.where((e) => customControlKeys.contains(e.key)),
        )
      : x as Map;
  return ButtonStyle(
    foregroundColor: state(m['foregroundColor'], (v) => color(v)),
    backgroundColor: state(m['backgroundColor'], (v) => color(v)),
    overlayColor: state(m['overlayColor'], (v) => color(v)),
    iconColor: state(m['iconColor'], (v) => color(v)),
    shadowColor: state(m['shadowColor'], (v) => color(v)),
    surfaceTintColor: state(m['surfaceTintColor'], (v) => color(v)),
    textStyle: state(m['textStyle'], textStyle),
    iconSize: state(m['iconSize'], (v) => number(v)),
    padding: state(m['padding'], insets),
    minimumSize: state(m['minimumSize'], size),
    maximumSize: state(m['maximumSize'], size),
    fixedSize: state(m['fixedSize'], size),
    side: state(m['side'], side),
    shape: state<OutlinedBorder>(
      m['shape'],
      (v) => v == 'circle'
          ? const CircleBorder()
          : v == 'stadium'
          ? const StadiumBorder()
          : RoundedRectangleBorder(borderRadius: radius(v)),
    ),
    elevation: state(m['elevation'], (v) => number(v)),
    mouseCursor: state<MouseCursor>(
      m['mouseCursor'],
      (v) => v == 'grab'
          ? SystemMouseCursors.grab
          : v == 'basic'
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
    ),
    visualDensity: m['visualDensity'] == null
        ? null
        : density(m['visualDensity']),
    tapTargetSize: m['tapTargetSize'] == null
        ? null
        : target(m['tapTargetSize']),
    animationDuration: m['animationDuration'] == null
        ? null
        : duration(m['animationDuration']),
  );
}

LiquidGlassThemeData glassTheme(Json m, [LiquidGlassThemeData? parent]) {
  final dark = m['brightness'] == 'dark';
  final b =
      parent ??
      (dark ? LiquidGlassThemeData.dark() : const LiquidGlassThemeData());
  final a = m['accessibility'] as Map? ?? {};
  final p = m['performance'] as Map? ?? {};
  final l = m['layout'] as Map? ?? {};
  final t = m['textTheme'] as Map? ?? {};
  final scheme = m['colorScheme'];
  return b.copyWith(
    brightness: m.containsKey('brightness')
        ? (dark ? Brightness.dark : Brightness.light)
        : b.brightness,
    accentColor: color(m['accentColor'], b.accentColor),
    colorScheme: scheme == null
        ? b.colorScheme
        : ColorScheme.fromSeed(
            seedColor: color(scheme['seedColor'] ?? m['accentColor']),
            brightness: dark ? Brightness.dark : Brightness.light,
          ).copyWith(
            primary: scheme['primary'] == null
                ? null
                : color(scheme['primary']),
            surface: scheme['surface'] == null
                ? null
                : color(scheme['surface']),
            onSurface: scheme['onSurface'] == null
                ? null
                : color(scheme['onSurface']),
          ),
    textTheme: b.textTheme.merge(
      TextTheme(
        bodyMedium: textStyle(t['bodyMedium']),
        labelLarge: textStyle(t['labelLarge']),
        headlineSmall: textStyle(t['headlineSmall']),
        titleLarge: textStyle(t['titleLarge']),
      ),
    ),
    visualDensity: m.containsKey('visualDensity')
        ? density(m['visualDensity'])
        : b.visualDensity,
    tapTargetSize: m.containsKey('tapTargetSize')
        ? target(m['tapTargetSize'])
        : b.tapTargetSize,
    layout: b.layout.copyWith(
      cardPadding: insets(l['cardPadding']),
      buttonPadding: insets(l['buttonPadding']),
      iconButtonPadding: insets(l['iconButtonPadding']),
      dialogPadding: insets(l['dialogPadding']),
      dialogMaxWidth: optionalNumber(l['dialogMaxWidth']),
      titleSpacing: optionalNumber(l['titleSpacing']),
      actionSpacing: optionalNumber(l['actionSpacing']),
      actionRunSpacing: optionalNumber(l['actionRunSpacing']),
      iconSize: l.containsKey('iconSize')
          ? optionalNumber(l['iconSize'])
          : b.layout.iconSize,
      appBarTitleSpacing: l.containsKey('appBarTitleSpacing')
          ? optionalNumber(l['appBarTitleSpacing'])
          : b.layout.appBarTitleSpacing,
    ),
    performance: b.performance.copyWith(
      quality: p.containsKey('quality')
          ? GlassQuality.values.firstWhere((v) => v.name == p['quality'])
          : null,
      blurEnabled: p['blurEnabled'],
      maxBlurSigma: optionalNumber(p['maxBlurSigma']),
      groupBackdropFilters: p['groupBackdropFilters'],
      enableNoise: p['enableNoise'],
      enableShadows: p['enableShadows'],
      enableAnimations: p['enableAnimations'],
    ),
    accessibility: b.accessibility.copyWith(
      highContrast: a['highContrast'],
      reduceMotion: a['reduceMotion'],
      reduceTransparency: a['reduceTransparency'],
    ),
    motion: m.containsKey('motion') ? motion(m['motion']) : b.motion,
    controlStyle: m['controlStyle'] == null
        ? b.controlStyle
        : control(m['controlStyle']),
    defaultStyle: glassStyle(m['defaultStyle'], b.defaultStyle),
    cardStyle: glassStyle(m['cardStyle'], b.cardStyle),
    buttonStyle: glassStyle(m['buttonStyle'], b.buttonStyle),
    dialogStyle: glassStyle(m['dialogStyle'], b.dialogStyle),
    appBarStyle: glassStyle(m['appBarStyle'], b.appBarStyle),
  );
}

class Runtime {
  Runtime(this.notify, this.log);
  final VoidCallback notify;
  final void Function(String) log;
  final controllers = <String, TextEditingController>{};
  final configured = <String, String>{};
  final focuses = <String, FocusNode>{};
  final values = <String, dynamic>{};
  final _nodes = <_RuntimeNodeState>{};
  _RuntimeNodeState? _building;
  bool _pruneScheduled = false, _disposed = false;
  void _prune() {
    if (_pruneScheduled || _disposed) return;
    _pruneScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pruneScheduled = false;
      if (_disposed) return;
      final usedControllers = {for (final n in _nodes) ...n.controllerIds};
      final usedFocus = {for (final n in _nodes) ...n.focusIds};
      for (final id in controllers.keys.toList()) {
        if (!usedControllers.contains(id)) {
          controllers.remove(id)?.dispose();
          configured.remove(id);
        }
      }
      for (final id in focuses.keys.toList()) {
        if (!usedFocus.contains(id)) focuses.remove(id)?.dispose();
      }
    });
  }

  TextEditingController controller(String id, String text) {
    _building?.controllerIds.add(id);
    final c = controllers.putIfAbsent(
      id,
      () => TextEditingController(text: text),
    );
    if (configured[id] != text) {
      c.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
      configured[id] = text;
    }
    return c;
  }

  FocusNode? focus(dynamic id, String path) {
    if (id == null) return null;
    final key = id == '@self' ? path : id.toString();
    _building?.focusIds.add(key);
    return focuses.putIfAbsent(key, () => FocusNode());
  }

  dynamic resolve(dynamic value) {
    if (value is! Map || !value.containsKey('bind')) return value;
    final resolved = values[value['bind']] ?? value['default'];
    return value['default'] is bool && resolved is! bool
        ? value['default']
        : resolved;
  }

  String interpolate(String text) => text.replaceAllMapped(
    RegExp(r'\{\{([^{}]+)\}\}'),
    (m) => (values[m[1]!.trim()] ?? 0).toString(),
  );
  VoidCallback? action(dynamic a, BuildContext context, String path) {
    if (a == null || a == 'none') return null;
    return () {
      if (!context.mounted) {
        log('当前组件已移除，动作已取消');
        return;
      }
      final m = a is Map ? a : <String, dynamic>{'action': a};
      final kind = m['action'];
      log('${chinesePath(path)} · ${chineseLabel(kind.toString())}');
      switch (kind) {
        case 'close':
          if (Navigator.canPop(context))
            Navigator.pop(context, m['result']);
          else
            log('当前演示没有可关闭的页面或弹窗');
        case 'increment':
          final key = m['key'] ?? 'count';
          if (values[key] != null && values[key] is! num) {
            log('变量类型不匹配：需要数字');
            return;
          }
          values[key] = (values[key] ?? 0) + 1;
          notify();
        case 'toggle':
          final key = m['key'] ?? 'selected';
          if (values[key] != null && values[key] is! bool) {
            log('变量类型不匹配：需要开关值');
            return;
          }
          values[key] = !(values[key] ?? false);
          notify();
        case 'focus':
          final target = focuses[m['target'] == '@self' ? path : m['target']];
          if (target == null)
            log('目标焦点不存在，请先设置目标组件的焦点绑定');
          else
            target.requestFocus();
        case 'setText':
          final target =
              controllers[m['target'] == '@self' ? path : m['target']];
          if (target == null)
            log('目标文本绑定不存在，请先设置目标输入框');
          else
            target.text = (m['text'] ?? '').toString();
        case 'dialog':
          showGlassDialog(
            context: context,
            builder: (c) => build(
              m['builder'] ?? {'type': 'GlassDialog'},
              c,
              '$path/dialog',
            ),
          ).then((result) {
            if (!_disposed) {
              log(
                '${chinesePath(path)} · ${result == null ? '弹窗已关闭' : '返回 $result'}',
              );
            }
          });
        case 'route':
          Navigator.of(context).push(
            GlassPageRoute(
              context: context,
              builder: (c) => Scaffold(
                appBar: AppBar(title: const Text('测试路由')),
                body: Center(
                  child: build(
                    m['builder'] ?? {'type': 'GlassCard'},
                    c,
                    '$path/route',
                  ),
                ),
              ),
            ),
          );
      }
    };
  }

  Widget build(
    dynamic spec,
    BuildContext context,
    String path, [
    int depth = 0,
  ]) => _RuntimeNode(
    key: ValueKey('$path/${spec is Map ? spec['type'] : 'Text'}'),
    runtime: this,
    actionContext: context,
    spec: spec,
    path: path,
    depth: depth,
  );

  Widget _dialogTrigger(
    Json m,
    BuildContext context,
    String path,
    Widget child,
  ) {
    Future<void> open() async {
      final opener = FocusManager.instance.primaryFocus;
      log('${chinesePath(path)} · 打开玻璃弹窗');
      final result = await showGlassDialog(
        context: context,
        builder: (c) => build(m['builder'], c, '$path/dialog'),
        barrierDismissible: m['barrierDismissible'] ?? true,
        useRootNavigator: m['useRootNavigator'] ?? true,
        routeSettings: RouteSettings(
          name: m['routeSettings']?['name'],
          arguments: m['routeSettings']?['arguments'],
        ),
        motion: m['motion'] == null ? null : motion(m['motion']),
      );
      if (opener?.context?.mounted == true && opener!.canRequestFocus) {
        opener.requestFocus();
      }
      log('${chinesePath(path)} · ${result == null ? '弹窗已关闭' : '返回 $result'}');
    }

    return switch (m['triggerKind']) {
      'iconButton' => GlassIconButton(
        icon: Icon(icons[m['triggerIcon']] ?? Icons.info_outline),
        tooltip: m['child'] is Map
            ? (m['child']['text'] ?? '打开说明').toString()
            : '打开说明',
        onPressed: open,
      ),
      'textLink' => TextButton(onPressed: open, child: child),
      'actionOnly' => const Text('无画布入口，请从编辑面板试用'),
      _ => GlassButton(onPressed: open, child: child),
    };
  }

  Widget _build(
    dynamic spec,
    BuildContext context,
    String path,
    int depth, {
    BuildContext? actionContext,
  }) {
    if (depth > 16) throw const FormatException('组件嵌套最多16层');
    if (spec == null) return const SizedBox.shrink();
    if (spec is String) return Text(sampleText(interpolate(spec)));
    final raw = spec as Map;
    final type = raw['type']?.toString() ?? 'Text';
    if (!componentDefaults.containsKey(type))
      throw FormatException('未知组件 $type');
    final m = <String, dynamic>{...componentDefaults[type]!, ...raw};
    dynamic v(String k) => resolve(m[k]);
    Widget node(dynamic s, String suffix) => build(
      s,
      context,
      '$path/${s is Map ? s['_nodeId'] ?? suffix : suffix}',
      depth + 1,
    );
    Widget child() => node(m['child'], 'child');
    List<Widget> children(String k) => (m[k] as List? ?? []).indexed
        .map((e) => node(e.$2, '$k/${e.$1}'))
        .toList();
    GlassStyle? appearance([GlassStyle base = GlassPresets.card]) =>
        m['style'] == null ? null : glassStyle(m['style'], base);
    VoidCallback? callback(String k) =>
        action(m[k], actionContext ?? context, path);
    final focusNode = focus(m['focusNode'], path);
    final style = appearance();
    final clip = Clip.values.firstWhere(
      (c) => c.name == (m['clipBehavior'] ?? 'antiAlias'),
    );
    final pad = insets(m['padding']);
    final highContrast =
        MediaQuery.of(context).highContrast ||
        LiquidGlassTheme.of(context).accessibility.highContrast;
    final readable = LiquidGlassTheme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xff17233b);
    var textAppearance = type == 'Text' ? textStyle(m['style']) : null;
    if (type == 'Text' && highContrast) {
      final paint = textAppearance?.foreground;
      textAppearance = paint == null
          ? (textAppearance ?? const TextStyle()).copyWith(color: readable)
          : textAppearance!.copyWith(
              foreground: Paint()
                ..color = readable
                ..style = paint.style
                ..strokeWidth = paint.strokeWidth,
            );
    }
    final widget = switch (type) {
      'GlassCard' => GlassCard(
        style: style,
        padding: pad,
        margin: insets(m['margin']),
        onTap: callback('onTap'),
        focusNode: focusNode,
        autofocus: m['autofocus'] ?? false,
        child: child(),
      ),
      'GlassButton' => GlassButton(
        style: appearance(GlassPresets.button),
        controlStyle: control(m['controlStyle'], custom: true),
        padding: pad,
        focusNode: focusNode,
        autofocus: m['autofocus'] ?? false,
        onPressed: callback('onPressed'),
        child: child(),
      ),
      'GlassIconButton' => GlassIconButton(
        icon: node(m['icon'], 'icon'),
        tooltip: m['tooltip'] ?? '',
        style: appearance(GlassPresets.button),
        controlStyle: control(m['controlStyle'], custom: true),
        focusNode: focusNode,
        autofocus: m['autofocus'] ?? false,
        onPressed: callback('onPressed'),
      ),
      'GlassSurface' => GlassSurface(
        width: optionalNumber(m['width']),
        height: optionalNumber(m['height']),
        constraints: constraints(m['constraints']),
        padding: pad,
        margin: insets(m['margin']),
        alignment: m['alignment'] == null ? null : alignment(m['alignment']),
        style: style,
        fallbackColor: m['fallbackColor'] == null
            ? null
            : color(m['fallbackColor']),
        clipBehavior: clip,
        enabled: m['enabled'] ?? true,
        child: child(),
      ),
      'AnimatedGlassSurface' => AnimatedGlassSurface(
        width: optionalNumber(m['width']),
        height: optionalNumber(m['height']),
        constraints: constraints(m['constraints']),
        padding: pad,
        margin: insets(m['margin']),
        alignment: m['alignment'] == null ? null : alignment(m['alignment']),
        style: m['style'] == null
            ? LiquidGlassTheme.of(context).defaultStyle
            : glassStyle(m['style']),
        fallbackColor: m['fallbackColor'] == null
            ? null
            : color(m['fallbackColor']),
        clipBehavior: clip,
        enabled: m['enabled'] ?? true,
        duration: m['duration'] == null ? null : duration(m['duration']),
        curve: m['curve'] == null ? null : curve(m['curve']),
        child: child(),
      ),
      'GlassTextField' => GlassTextField(
        controller: m['controller'] == null
            ? null
            : controller(
                m['controller'] == '@self' ? path : m['controller'].toString(),
                (m['text'] ?? '').toString(),
              ),
        focusNode: focusNode,
        enabled: m['enabled'],
        readOnly: m['readOnly'] ?? false,
        autofocus: m['autofocus'] ?? false,
        style: textStyle(m['style']),
        textInputAction: TextInputAction.values.firstWhere(
          (x) => x.name == (m['textInputAction'] ?? 'done'),
        ),
        decoration: decoration(
          m['decoration'] as Map? ?? {},
          context,
          path,
          depth,
        ),
        onChanged: m['onChanged'] == null
            ? null
            : (text) {
                log('${chinesePath(path)} · 内容修改：$text');
                callback('onChanged')?.call();
              },
        onSubmitted: m['onSubmitted'] == null
            ? null
            : (text) {
                log('${chinesePath(path)} · 输入提交：$text');
                callback('onSubmitted')?.call();
              },
      ),
      'GlassNavigationItem' => GlassNavigationItem(
        label: interpolate(m['label'] ?? ''),
        leading: m['leading'] == null ? null : node(m['leading'], 'leading'),
        trailing: m['trailing'] == null
            ? null
            : node(m['trailing'], 'trailing'),
        selected: v('selected') ?? false,
        indent: number(m['indent']),
        onPressed: callback('onPressed'),
        focusNode: focusNode,
        controlStyle: control(m['controlStyle']),
      ),
      'GlassTab' => GlassTab(
        label: interpolate(m['label'] ?? ''),
        leading: m['leading'] == null ? null : node(m['leading'], 'leading'),
        selected: v('selected') ?? false,
        onSelected: callback('onSelected'),
        onClose: callback('onClose'),
        focusNode: focusNode,
        controlStyle: control(m['controlStyle']),
      ),
      'GlassToolbar' => SizedBox(
        width: double.infinity,
        child: GlassToolbar(
          spacing: optionalNumber(m['spacing']),
          alignment: WrapAlignment.values.firstWhere(
            (a) => a.name == (m['alignment'] ?? 'start'),
          ),
          children: children('children'),
        ),
      ),
      'GlassMenu' => GlassMenu(
        trigger: node(m['trigger'], 'trigger'),
        items: children('items'),
        enabled: m['enabled'] ?? true,
        focusNode: focusNode,
        onOpen: callback('onOpen'),
        onClose: callback('onClose'),
        controlStyle: control(m['controlStyle']),
      ),
      'GlassAppBar' => SizedBox(
        height:
            number(m['toolbarHeight'], 56) +
            (m['bottom'] == null ? 0 : number(m['bottomHeight'], 40)),
        child: GlassAppBar(
          title: node(m['title'], 'title'),
          leading: m['leading'] == null ? null : node(m['leading'], 'leading'),
          actions: children('actions'),
          style: appearance(GlassPresets.appBar),
          bottom: m['bottom'] == null
              ? null
              : PreferredSize(
                  preferredSize: Size.fromHeight(number(m['bottomHeight'], 40)),
                  child: node(m['bottom'], 'bottom'),
                ),
          toolbarHeight: number(m['toolbarHeight'], 56),
          automaticallyImplyLeading: m['automaticallyImplyLeading'] ?? true,
        ),
      ),
      'GlassDialog' => GlassDialog(
        title: m['title'] == null ? null : node(m['title'], 'title'),
        content: node(m['content'], 'content'),
        actions: children('actions'),
        style: appearance(GlassPresets.dialog),
        semanticLabel: m['semanticLabel'],
        padding: pad,
        constraints: constraints(m['constraints']),
      ),
      'showGlassDialog' => _dialogTrigger(m, context, path, child()),
      'GlassPageRoute' => GlassButton(
        onPressed: () {
          log('${chinesePath(path)} · 打开示例页面');
          Navigator.of(context).push(
            GlassPageRoute(
              context: context,
              motion: motion(m['motion']),
              reduceMotion: m['reduceMotion'] ?? false,
              settings: RouteSettings(
                name: m['settings']?['name'],
                arguments: m['settings']?['arguments'],
              ),
              fullscreenDialog: m['fullscreenDialog'] ?? false,
              builder: (c) => Scaffold(
                appBar: AppBar(title: const Text('返回组件实验台')),
                body: Center(child: build(m['builder'], c, '$path/page')),
              ),
            ),
          );
        },
        child: child(),
      ),
      'GlassBackdrop' => GlassBackdrop(
        colors: (m['colors'] as List).map((c) => color(c)).toList(),
        gradient: highContrast
            ? LinearGradient(
                colors: [
                  readable == Colors.white
                      ? const Color(0xff202a3c)
                      : const Color(0xffedf1f8),
                  readable == Colors.white
                      ? const Color(0xff202a3c)
                      : const Color(0xffedf1f8),
                ],
              )
            : gradient(m['gradient']),
        intensity: highContrast ? 0 : number(m['intensity'], 1),
        animate: m['animate'] ?? false,
        child: Center(child: child()),
      ),
      'GlassGroup' => GlassGroup(
        overlapping: m['overlapping'] ?? false,
        child: child(),
      ),
      'LiquidGlassTheme' =>
        m['merge'] == true
            ? LiquidGlassTheme.merge(
                data: (parent) =>
                    glassTheme(Map<String, dynamic>.from(m['data']), parent),
                child: Builder(
                  builder: (c) =>
                      build(m['child'], c, '$path/theme', depth + 1),
                ),
              )
            : LiquidGlassTheme(
                data: glassTheme(Map<String, dynamic>.from(m['data'])),
                child: Builder(
                  builder: (c) =>
                      build(m['child'], c, '$path/theme', depth + 1),
                ),
              ),
      'Icon' => Icon(
        icons[m['icon']] ?? Icons.widgets_outlined,
        size: optionalNumber(m['size']),
        color: highContrast
            ? readable
            : m['color'] == null
            ? null
            : color(m['color']),
      ),
      'Row' => Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.values.firstWhere(
          (a) => a.name == (m['alignment'] ?? 'center'),
        ),
        spacing: number(m['spacing'], 12),
        children: [
          for (final child in children('children'))
            Flexible(fit: FlexFit.loose, child: child),
        ],
      ),
      'Column' => LayoutBuilder(
        builder: (context, limits) {
          final column = Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.values.firstWhere(
              (a) => a.name == (m['alignment'] ?? 'center'),
            ),
            spacing: number(m['spacing'], 12),
            children: children('children'),
          );
          return limits.hasBoundedHeight
              ? SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: limits.maxHeight),
                    child: column,
                  ),
                )
              : column;
        },
      ),
      'MenuItemButton' => MenuItemButton(
        onPressed: callback('onPressed'),
        leadingIcon: m['leadingIcon'] == null
            ? null
            : node(m['leadingIcon'], 'leading'),
        trailingIcon: m['trailingIcon'] == null
            ? null
            : node(m['trailingIcon'], 'trailing'),
        closeOnActivate: m['closeOnActivate'] ?? true,
        child: child(),
      ),
      _ => Text(
        sampleText(interpolate(m['text'] ?? '')),
        style: textAppearance,
        maxLines: (m['maxLines'] as num?)?.toInt(),
        textAlign: TextAlign.values.firstWhere(
          (a) => a.name == (m['textAlign'] ?? 'start'),
        ),
      ),
    };
    return KeyedSubtree(key: ValueKey(path), child: widget);
  }

  InputDecoration decoration(
    Map m,
    BuildContext context,
    String path,
    int depth,
  ) {
    Widget? n(String k) =>
        m[k] == null ? null : build(m[k], context, '$path/$k', depth + 1);
    InputBorder? border(dynamic b) => b == null
        ? null
        : b == 'none'
        ? InputBorder.none
        : OutlineInputBorder(
            borderRadius: radius(b['radius'] ?? 12),
            borderSide: BorderSide(
              color: color(b['color']),
              width: number(b['width'], 1),
            ),
          );
    return InputDecoration(
      hintText: m['hintText'],
      labelText: m['labelText'],
      helperText: m['helperText'],
      errorText: m['errorText'],
      prefixText: m['prefixText'],
      suffixText: m['suffixText'],
      prefixIcon: n('prefixIcon'),
      suffixIcon: n('suffixIcon'),
      prefix: n('prefix'),
      suffix: n('suffix'),
      filled: m['filled'],
      fillColor: m['fillColor'] == null ? null : color(m['fillColor']),
      isDense: m['isDense'],
      enabled: m['enabled'] ?? true,
      contentPadding: insets(m['contentPadding']),
      labelStyle: textStyle(m['labelStyle']),
      hintStyle: textStyle(m['hintStyle']),
      helperStyle: textStyle(m['helperStyle']),
      errorStyle: textStyle(m['errorStyle']),
      floatingLabelStyle: textStyle(m['floatingLabelStyle']),
      border: border(m['border']),
      enabledBorder: border(m['enabledBorder']),
      focusedBorder: border(m['focusedBorder']),
      disabledBorder: border(m['disabledBorder']),
      errorBorder: border(m['errorBorder']),
      focusedErrorBorder: border(m['focusedErrorBorder']),
    );
  }

  void dispose() {
    _disposed = true;
    for (final c in controllers.values) {
      c.dispose();
    }
    for (final f in focuses.values) {
      f.dispose();
    }
  }
}

class _RuntimeNode extends StatefulWidget {
  const _RuntimeNode({
    super.key,
    required this.runtime,
    required this.actionContext,
    required this.spec,
    required this.path,
    required this.depth,
  });
  final Runtime runtime;
  final BuildContext actionContext;
  final dynamic spec;
  final String path;
  final int depth;
  @override
  State<_RuntimeNode> createState() => _RuntimeNodeState();
}

class _RuntimeNodeState extends State<_RuntimeNode> {
  final controllerIds = <String>{}, focusIds = <String>{};
  @override
  void initState() {
    super.initState();
    widget.runtime._nodes.add(this);
  }

  @override
  void didUpdateWidget(_RuntimeNode old) {
    super.didUpdateWidget(old);
    if (old.runtime != widget.runtime) {
      old.runtime._nodes.remove(this);
      old.runtime._prune();
      widget.runtime._nodes.add(this);
    }
  }

  @override
  Widget build(BuildContext context) {
    controllerIds.clear();
    focusIds.clear();
    widget.runtime._building = this;
    try {
      return widget.runtime._build(
        widget.spec,
        context,
        widget.path,
        widget.depth,
        actionContext: widget.actionContext,
      );
    } finally {
      widget.runtime._building = null;
      widget.runtime._prune();
    }
  }

  @override
  void dispose() {
    widget.runtime._nodes.remove(this);
    widget.runtime._prune();
    super.dispose();
  }
}

Json module(String type, int id, {double x = 40, double y = 40}) => {
  'id': 'node-$id',
  'type': type,
  'x': x,
  'y': y,
  'w': type == 'GlassIconButton' ? 100 : 360,
  'h': switch (type) {
    'GlassAppBar' => 90,
    'GlassIconButton' => 100,
    'GlassButton' ||
    'GlassNavigationItem' ||
    'GlassTab' ||
    'GlassToolbar' ||
    'GlassMenu' ||
    'GlassTextField' ||
    'showGlassDialog' ||
    'GlassPageRoute' => 110,
    _ => 220,
  },
  'props': clone(componentDefaults[type]!),
};
Json initialScene() => {
  'version': 1,
  'theme': themeDefaults(),
  'modules': [
    module('GlassCard', 1, x: 36, y: 32)
      ..['props'] = {
        'child': {
          'type': 'Column',
          'children': [
            iconNode(),
            textNode('灵感，随手成形'),
            {
              'type': 'Text',
              'text': '拖动模块标题，或者在右侧修改每一个参数。',
              'style': {'fontSize': 13},
            },
          ],
          'spacing': 14,
        },
        'padding': 24,
      },
    module('GlassButton', 2, x: 430, y: 32),
    module('GlassTextField', 3, x: 430, y: 180),
    module('GlassMenu', 4, x: 36, y: 310),
    module('showGlassDialog', 5, x: 430, y: 340),
  ],
};
void validateScene(Json scene, {Json? previous, bool legacy = false}) {
  if (scene['version'] != 1 ||
      scene['theme'] is! Map ||
      scene['modules'] is! List) {
    throw const FormatException('布局需包含格式版本、主题和模块列表');
  }
  final modules = scene['modules'] as List;
  if (modules.length > 100) throw const FormatException('每个布局最多100个模块');
  validateConfig(
    scene['theme'],
    'theme',
    '全局主题',
    previous: previous?['theme'],
    legacy: legacy,
  );
  glassTheme(Map<String, dynamic>.from(scene['theme']));
  final ids = <String>{};
  final explicitFocus = <String>{};
  void checkFocus(Map node) {
    final id = node['focusNode'];
    if (id is String && id != '@self' && !explicitFocus.add(id))
      throw const FormatException('多个组件不能共用同一个焦点标识，请使用当前组件或独立标识');
    void visit(dynamic v, String kind) {
      if (kind.startsWith('slot:') && v is Map)
        checkFocus(v);
      else if (kind.startsWith('list:') && v is List) {
        for (final child in v) {
          visit(child, kind.substring(5));
        }
      } else if (kind == 'action' && v is Map && v['builder'] is Map)
        checkFocus(v['builder']);
    }

    final fields = schemaFor('component:${node['type']}');
    for (final e in node.entries) {
      visit(e.value, fields[e.key] ?? 'unsupported');
    }
  }

  for (var i = 0; i < modules.length; i++) {
    final raw = modules[i];
    if (raw is! Map ||
        raw['id'] is! String ||
        !ids.add(raw['id']) ||
        !componentDefaults.containsKey(raw['type']) ||
        raw['props'] is! Map) {
      throw FormatException('模块${i + 1}的编号、类型或参数无效');
    }
    final old = (previous?['modules'] as List?)
        ?.where((m) => m['id'] == raw['id'])
        .firstOrNull;
    for (final k in ['x', 'y', 'w', 'h']) {
      final n = number(raw[k]);
      final min = k == 'w'
          ? 70
          : k == 'h'
          ? 65
          : 0;
      final max = (k == 'w' || k == 'h')
          ? 1100
          : 1200 - number(raw[k == 'x' ? 'w' : 'h']);
      if (n < min || n > max)
        throw FormatException('模块${i + 1}的${chineseLabel(k)}应在$min至$max之间');
    }
    final needed = requiredFrame(raw);
    if (number(raw['w']) < needed.width || number(raw['h']) < needed.height)
      throw FormatException(
        '模块${i + 1}的内部尺寸需要至少${needed.width}×${needed.height}的模块外框，请先扩大模块',
      );
    final node = <String, dynamic>{...raw['props'], 'type': raw['type']};
    validateConfig(
      node,
      'slot:root',
      '模块${i + 1}',
      previous: old == null ? null : {...old['props'], 'type': old['type']},
      legacy: legacy,
    );
    checkFocus(node);
  }
}

Size requiredFrame(Map module) {
  final p = module['props'] as Map;
  var w = 70.0, h = 65.0;
  if (['GlassSurface', 'AnimatedGlassSurface'].contains(module['type'])) {
    if (p['width'] is num) w = math.max(w, number(p['width']) + 3);
    if (p['height'] is num) h = math.max(h, number(p['height']) + 31);
  }
  if ([
        'GlassSurface',
        'AnimatedGlassSurface',
        'GlassDialog',
      ].contains(module['type']) &&
      p['constraints'] is Map) {
    w = math.max(w, number(p['constraints']['minWidth']) + 3);
    h = math.max(h, number(p['constraints']['minHeight']) + 31);
  }
  if (module['type'] == 'GlassAppBar')
    h = math.max(
      h,
      number(p['toolbarHeight'], 56) +
          (p['bottom'] == null ? 0 : number(p['bottomHeight'], 40)) +
          31,
    );
  return Size(w, h);
}
