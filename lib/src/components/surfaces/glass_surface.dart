import 'package:flutter/material.dart';
import '../../core/style.dart';
import '../../core/surface_renderer.dart';
import '../../theme/theme.dart';

/// Bounded backdrop filtering with crisp, unfiltered foreground content.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.constraints,
    this.padding,
    this.margin,
    this.alignment,
    this.style,
    this.clipBehavior = Clip.antiAlias,
    this.enabled = true,
    this.fallbackColor,
  });
  final Widget child;
  final double? width, height;
  final BoxConstraints? constraints;
  final EdgeInsetsGeometry? padding, margin;
  final AlignmentGeometry? alignment;
  final GlassStyle? style;
  final Clip clipBehavior;

  /// False disables decoration and filtering while preserving layout and clip.
  final bool enabled;
  final Color? fallbackColor;

  @override
  Widget build(BuildContext context) {
    final theme = LiquidGlassTheme.of(context);
    final performance = theme.performance;
    final highContrast =
        theme.accessibility.highContrast ||
        MediaQuery.maybeOf(context)?.highContrast == true;
    final opaque = highContrast || theme.accessibility.reduceTransparency;
    var s = style ?? theme.defaultStyle;
    if (highContrast) {
      s = s.copyWith(
        borderColor: theme.brightness == Brightness.dark
            ? Colors.white
            : const Color(0xff17233b),
      );
    }
    return GlassSurfaceRenderer(
      style: s,
      groupStyle: theme.defaultStyle,
      performance: performance,
      highContrast: highContrast,
      opaque: opaque,
      fallbackColor:
          fallbackColor ??
          (theme.brightness == Brightness.dark
              ? const Color(0xff202a3c)
              : const Color(0xffedf1f8)),
      width: width,
      height: height,
      constraints: constraints,
      padding: padding,
      margin: margin,
      alignment: alignment,
      clipBehavior: clipBehavior,
      enabled: enabled,
      child: child,
    );
  }
}
