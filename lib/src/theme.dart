import 'package:flutter/material.dart';
import 'motion.dart';
import 'style.dart';

enum GlassQuality { low, balanced, high, adaptive }

/// Explicit limits, not a device benchmark. Adaptive uses conservative defaults.
@immutable
class GlassPerformanceConfig {
  const GlassPerformanceConfig({
    this.quality = GlassQuality.adaptive,
    this.blurEnabled = true,
    this.maxBlurSigma = 20,
    this.groupBackdropFilters = true,
    this.enableNoise = false,
    this.enableShadows = true,
    this.enableAnimations = true,
  }) : assert(maxBlurSigma >= 0 && maxBlurSigma < double.infinity);
  final GlassQuality quality;
  final bool blurEnabled;
  final double maxBlurSigma;
  final bool groupBackdropFilters;
  final bool enableNoise;
  final bool enableShadows;
  final bool enableAnimations;

  double get effectiveMaxBlurSigma => switch (quality) {
    GlassQuality.low => 0,
    GlassQuality.balanced || GlassQuality.adaptive => maxBlurSigma.clamp(0, 16),
    GlassQuality.high => maxBlurSigma,
  };
}

/// System high contrast and reduced motion always take precedence.
@immutable
class GlassAccessibilityConfig {
  const GlassAccessibilityConfig({
    this.highContrast = false,
    this.reduceMotion = false,
    this.reduceTransparency = false,
  });
  final bool highContrast;
  final bool reduceMotion;
  final bool reduceTransparency;
}

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
  );

  @override
  LiquidGlassThemeData lerp(covariant LiquidGlassThemeData? other, double t) {
    if (other == null) return this;
    return LiquidGlassThemeData(
      brightness: t < .5 ? brightness : other.brightness,
      accentColor: Color.lerp(accentColor, other.accentColor, t)!,
      defaultStyle: GlassStyle.lerp(defaultStyle, other.defaultStyle, t),
      cardStyle: GlassStyle.lerp(cardStyle, other.cardStyle, t),
      buttonStyle: GlassStyle.lerp(buttonStyle, other.buttonStyle, t),
      dialogStyle: GlassStyle.lerp(dialogStyle, other.dialogStyle, t),
      appBarStyle: GlassStyle.lerp(appBarStyle, other.appBarStyle, t),
      motion: t < .5 ? motion : other.motion,
      performance: t < .5 ? performance : other.performance,
      accessibility: t < .5 ? accessibility : other.accessibility,
    );
  }
}

/// Local override; alternatively register LiquidGlassThemeData in ThemeData.extensions.
class LiquidGlassTheme extends InheritedTheme {
  const LiquidGlassTheme({super.key, required this.data, required super.child});
  final LiquidGlassThemeData data;
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
