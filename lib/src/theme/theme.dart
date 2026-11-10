import 'package:flutter/material.dart';
import '../core/config.dart';
import '../core/motion_spec.dart';
import '../core/style.dart';
import 'layout.dart';

const _unset = Object();

@immutable
class LiquidGlassThemeData extends ThemeExtension<LiquidGlassThemeData> {
  const LiquidGlassThemeData({
    this.brightness = Brightness.light,
    this.accentColor = const Color(0xff4263eb),
    this.defaultStyle = GlassPresets.card,
    this.cardStyle = GlassPresets.card,
    this.buttonStyle = GlassPresets.button,
    this.dialogStyle = GlassPresets.dialog,
    this.appBarStyle = GlassPresets.appBar,
    this.motion = const GlassMotionSpec(),
    this.performance = const GlassPerformanceConfig(),
    this.accessibility = const GlassAccessibilityConfig(),
    this.colorScheme,
    this.textTheme = const TextTheme(),
    this.layout = const GlassLayout(),
    this.controlStyle = const ButtonStyle(),
    this.visualDensity = VisualDensity.standard,
    this.tapTargetSize = MaterialTapTargetSize.padded,
  });

  factory LiquidGlassThemeData.dark({
    Color accentColor = const Color(0xff9babff),
  }) {
    GlassStyle darken(GlassStyle s) => s.copyWith(
      tintColor: const Color(0xff182235),
      tintOpacity: s == GlassPresets.dialog ? .94 : .65,
    );
    return LiquidGlassThemeData(
      brightness: Brightness.dark,
      accentColor: accentColor,
      defaultStyle: darken(GlassPresets.card),
      cardStyle: darken(GlassPresets.card),
      buttonStyle: darken(GlassPresets.button),
      dialogStyle: darken(GlassPresets.dialog),
      appBarStyle: darken(GlassPresets.appBar),
    );
  }
  final Brightness brightness;
  final Color accentColor;
  final GlassStyle defaultStyle,
      cardStyle,
      buttonStyle,
      dialogStyle,
      appBarStyle;
  final GlassMotionSpec motion;
  final GlassPerformanceConfig performance;
  final GlassAccessibilityConfig accessibility;

  /// Null retains the legacy brightness-based colors.
  final ColorScheme? colorScheme;

  /// Partial typography merged into the inherited Flutter text styles.
  final TextTheme textTheme;
  final GlassLayout layout;

  /// State-aware control overrides. See design-system.md for supported fields.
  final ButtonStyle controlStyle;
  final VisualDensity visualDensity;
  final MaterialTapTargetSize tapTargetSize;

  Color get foregroundColor =>
      colorScheme?.onSurface ??
      (brightness == Brightness.dark ? Colors.white : const Color(0xff17233b));
  Color get surfaceColor =>
      colorScheme?.surface ??
      (brightness == Brightness.dark
          ? const Color(0xff202a3c)
          : const Color(0xffedf1f8));
  Color get focusColor => colorScheme?.primary ?? accentColor;

  @override
  LiquidGlassThemeData copyWith({
    Brightness? brightness,
    Color? accentColor,
    GlassStyle? defaultStyle,
    GlassStyle? cardStyle,
    GlassStyle? buttonStyle,
    GlassStyle? dialogStyle,
    GlassStyle? appBarStyle,
    GlassMotionSpec? motion,
    GlassPerformanceConfig? performance,
    GlassAccessibilityConfig? accessibility,
    Object? colorScheme = _unset,
    TextTheme? textTheme,
    GlassLayout? layout,
    ButtonStyle? controlStyle,
    VisualDensity? visualDensity,
    MaterialTapTargetSize? tapTargetSize,
  }) => LiquidGlassThemeData(
    brightness: brightness ?? this.brightness,
    accentColor: accentColor ?? this.accentColor,
    defaultStyle: defaultStyle ?? this.defaultStyle,
    cardStyle: cardStyle ?? this.cardStyle,
    buttonStyle: buttonStyle ?? this.buttonStyle,
    dialogStyle: dialogStyle ?? this.dialogStyle,
    appBarStyle: appBarStyle ?? this.appBarStyle,
    motion: motion ?? this.motion,
    performance: performance ?? this.performance,
    accessibility: accessibility ?? this.accessibility,
    colorScheme: identical(colorScheme, _unset)
        ? this.colorScheme
        : colorScheme as ColorScheme?,
    textTheme: textTheme ?? this.textTheme,
    layout: layout ?? this.layout,
    controlStyle: controlStyle ?? this.controlStyle,
    visualDensity: visualDensity ?? this.visualDensity,
    tapTargetSize: tapTargetSize ?? this.tapTargetSize,
  );

  @override
  LiquidGlassThemeData lerp(covariant LiquidGlassThemeData? other, double t) {
    if (other == null) return this;
    if (t <= 0) return this;
    if (t >= 1) return other;
    return LiquidGlassThemeData(
      brightness: t < .5 ? brightness : other.brightness,
      accentColor: Color.lerp(accentColor, other.accentColor, t)!,
      defaultStyle: _materialLerp(defaultStyle, other.defaultStyle, t),
      cardStyle: _materialLerp(cardStyle, other.cardStyle, t),
      buttonStyle: _materialLerp(buttonStyle, other.buttonStyle, t),
      dialogStyle: _materialLerp(dialogStyle, other.dialogStyle, t),
      appBarStyle: _materialLerp(appBarStyle, other.appBarStyle, t),
      motion: t < .5 ? motion : other.motion,
      performance: GlassPerformanceConfig(
        quality:
            performance.effectiveMaxBlurSigma <=
                other.performance.effectiveMaxBlurSigma
            ? performance.quality
            : other.performance.quality,
        maxBlurSigma:
            performance.effectiveMaxBlurSigma <
                other.performance.effectiveMaxBlurSigma
            ? performance.effectiveMaxBlurSigma
            : other.performance.effectiveMaxBlurSigma,
        blurEnabled: performance.blurEnabled && other.performance.blurEnabled,
        groupBackdropFilters:
            performance.groupBackdropFilters &&
            other.performance.groupBackdropFilters,
        enableNoise: performance.enableNoise && other.performance.enableNoise,
        enableShadows:
            performance.enableShadows && other.performance.enableShadows,
        enableAnimations:
            performance.enableAnimations && other.performance.enableAnimations,
      ),
      accessibility: GlassAccessibilityConfig(
        highContrast:
            accessibility.highContrast || other.accessibility.highContrast,
        reduceMotion:
            accessibility.reduceMotion || other.accessibility.reduceMotion,
        reduceTransparency:
            accessibility.reduceTransparency ||
            other.accessibility.reduceTransparency,
      ),
      colorScheme: colorScheme == null || other.colorScheme == null
          ? (t < .5 ? colorScheme : other.colorScheme)
          : ColorScheme.lerp(colorScheme!, other.colorScheme!, t),
      textTheme: TextTheme.lerp(textTheme, other.textTheme, t),
      layout: GlassLayout.lerp(layout, other.layout, t),
      controlStyle: ButtonStyle.lerp(controlStyle, other.controlStyle, t)!,
      visualDensity: VisualDensity.lerp(visualDensity, other.visualDensity, t),
      tapTargetSize: t < .5 ? tapTargetSize : other.tapTargetSize,
    );
  }
}

/// Local override; alternatively register LiquidGlassThemeData in ThemeData.extensions.
class LiquidGlassTheme extends InheritedTheme {
  const LiquidGlassTheme({super.key, required this.data, required super.child});
  final LiquidGlassThemeData data;

  /// Inherit the nearest theme and explicitly copy only the fields to override.
  static Widget merge({
    Key? key,
    required LiquidGlassThemeData Function(LiquidGlassThemeData parent) data,
    required Widget child,
  }) => Builder(
    key: key,
    builder: (context) =>
        LiquidGlassTheme(data: data(of(context)), child: child),
  );
  static LiquidGlassThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LiquidGlassTheme>()?.data ??
      Theme.of(context).extension<LiquidGlassThemeData>() ??
      (Theme.of(context).brightness == Brightness.dark
          ? LiquidGlassThemeData.dark()
          : const LiquidGlassThemeData());
  @override
  bool updateShouldNotify(LiquidGlassTheme oldWidget) => data != oldWidget.data;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      LiquidGlassTheme(data: data, child: child);
}

bool glassReduceMotion(BuildContext context) {
  final theme = LiquidGlassTheme.of(context);
  return MediaQuery.maybeOf(context)?.disableAnimations == true ||
      MediaQuery.maybeOf(context)?.accessibleNavigation == true ||
      theme.accessibility.reduceMotion ||
      !theme.performance.enableAnimations;
}

GlassStyle _materialLerp(GlassStyle a, GlassStyle b, double t) =>
    GlassStyle.lerp(a, b, t).copyWith(
      blurSigmaX: b.blurSigmaX,
      blurSigmaY: b.blurSigmaY,
      blurEnabled: b.blurEnabled,
    );

// A state resolver returning null inherits the corresponding theme state.
WidgetStateProperty<T?>? _mergeState<T>(
  WidgetStateProperty<T?>? local,
  WidgetStateProperty<T?>? inherited,
) {
  if (local == null) return inherited;
  if (inherited == null) return local;
  return WidgetStateProperty.resolveWith(
    (states) => local.resolve(states) ?? inherited.resolve(states),
  );
}

ButtonStyle glassControlStyle(BuildContext context, ButtonStyle? local) {
  final inherited = LiquidGlassTheme.of(context).controlStyle;
  if (local == null) return inherited;
  return local
      .merge(inherited)
      .copyWith(
        foregroundColor: _mergeState(
          local.foregroundColor,
          inherited.foregroundColor,
        ),
        backgroundColor: _mergeState(
          local.backgroundColor,
          inherited.backgroundColor,
        ),
        overlayColor: _mergeState(local.overlayColor, inherited.overlayColor),
        textStyle: _mergeState(local.textStyle, inherited.textStyle),
        iconSize: _mergeState(local.iconSize, inherited.iconSize),
        padding: _mergeState(local.padding, inherited.padding),
        minimumSize: _mergeState(local.minimumSize, inherited.minimumSize),
        side: _mergeState(local.side, inherited.side),
      );
}

// Keep legacy inherited text when no semantic or typography override was set.
TextStyle glassTextStyle(BuildContext context, TextStyle? style) {
  final theme = LiquidGlassTheme.of(context);
  final mismatch = theme.brightness != Theme.of(context).brightness;
  final color = style?.color ?? theme.colorScheme?.onSurface;
  final highContrast =
      theme.accessibility.highContrast ||
      MediaQuery.maybeOf(context)?.highContrast == true;
  final resolved = highContrast && (color != null || mismatch)
      ? (theme.brightness == Brightness.dark
            ? Colors.white
            : const Color(0xff17233b))
      : color ?? (mismatch ? theme.foregroundColor : null);
  return (style ?? const TextStyle()).copyWith(color: resolved);
}

// Density changes padding; constraints separately enforce the touch target.
EdgeInsets glassPadding(
  BuildContext context,
  EdgeInsetsGeometry padding, {
  VisualDensity? density,
}) {
  final d = density ?? LiquidGlassTheme.of(context).visualDensity;
  final p = padding.resolve(Directionality.of(context));
  return EdgeInsets.fromLTRB(
    (p.left + d.horizontal * 2).clamp(0, double.infinity),
    (p.top + d.vertical * 2).clamp(0, double.infinity),
    (p.right + d.horizontal * 2).clamp(0, double.infinity),
    (p.bottom + d.vertical * 2).clamp(0, double.infinity),
  );
}
