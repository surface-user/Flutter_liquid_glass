import 'package:flutter/material.dart';
import '../../core/style.dart';
import '../../theme/theme.dart';
import 'glass_surface.dart';

/// Interpolates visual style. Blur sigma is held at the target throughout the
/// transition, avoiding an expensive changing blur kernel on every frame.
class AnimatedGlassSurface extends StatelessWidget {
  const AnimatedGlassSurface({
    super.key,
    required this.child,
    required this.style,
    this.duration = const Duration(milliseconds: 240),
    this.curve = Curves.easeOutCubic,
    this.width,
    this.height,
    this.constraints,
    this.padding,
    this.margin,
    this.alignment,
    this.clipBehavior = Clip.antiAlias,
    this.enabled = true,
    this.fallbackColor,
  });
  final Widget child;
  final GlassStyle style;
  final Duration duration;
  final Curve curve;
  final double? width, height;
  final BoxConstraints? constraints;
  final EdgeInsetsGeometry? padding, margin;
  final AlignmentGeometry? alignment;
  final Clip clipBehavior;
  final bool enabled;
  final Color? fallbackColor;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<GlassStyle>(
    tween: _StyleTween(end: style),
    duration: glassReduceMotion(context) ? Duration.zero : duration,
    curve: curve,
    child: child,
    builder: (context, value, child) => GlassSurface(
      style: value.copyWith(
        blurSigmaX: style.blurSigmaX,
        blurSigmaY: style.blurSigmaY,
        blurEnabled: style.blurEnabled,
      ),
      width: width,
      height: height,
      constraints: constraints,
      padding: padding,
      margin: margin,
      alignment: alignment,
      clipBehavior: clipBehavior,
      enabled: enabled,
      fallbackColor: fallbackColor,
      child: child!,
    ),
  );
}

class _StyleTween extends Tween<GlassStyle> {
  _StyleTween({required GlassStyle super.end});
  @override
  GlassStyle lerp(double t) => GlassStyle.lerp(begin ?? end!, end!, t);
}
