import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'config.dart';
import 'glass_group.dart';
import 'style.dart';

/// Internal renderer. Theme and system constraints are resolved by the wrapper.
class GlassSurfaceRenderer extends StatelessWidget {
  const GlassSurfaceRenderer({
    super.key,
    required this.child,
    required this.style,
    required this.groupStyle,
    required this.performance,
    required this.highContrast,
    required this.opaque,
    required this.fallbackColor,
    this.width,
    this.height,
    this.constraints,
    this.padding,
    this.margin,
    this.alignment,
    this.clipBehavior = Clip.antiAlias,
    this.enabled = true,
  });
  final Widget child;
  final GlassStyle style, groupStyle;
  final GlassPerformanceConfig performance;
  final bool highContrast, opaque;
  final Color fallbackColor;
  final double? width, height;
  final BoxConstraints? constraints;
  final EdgeInsetsGeometry? padding, margin;
  final AlignmentGeometry? alignment;
  final Clip clipBehavior;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final s = style;
    final maxSigma = performance.effectiveMaxBlurSigma;
    final blur =
        enabled &&
        !opaque &&
        performance.blurEnabled &&
        s.blurEnabled &&
        maxSigma > 0 &&
        (s.blurSigmaX > 0 || s.blurSigmaY > 0);
    final fallback = fallbackColor.withValues(alpha: 1);
    final radius = s.shape == BoxShape.circle ? null : s.borderRadius;
    final shape = s.shape == BoxShape.circle
        ? const CircleBorder()
        : RoundedRectangleBorder(borderRadius: s.borderRadius);
    Widget content = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: alignment == null
          ? child
          : Align(alignment: alignment!, child: child),
    );
    // Give direct Material/InkWell descendants the same clipping geometry.
    content = Material(
      type: MaterialType.transparency,
      shape: shape,
      child: content,
    );
    if (enabled) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          shape: s.shape,
          borderRadius: radius,
          color: blur
              ? s.tintColor.withValues(alpha: s.tintColor.a * s.tintOpacity)
              : fallback,
          gradient: opaque ? null : s.backgroundGradient,
        ),
        child: CustomPaint(
          foregroundPainter: _GlassPainter(
            s,
            highContrast: highContrast,
            noise: performance.enableNoise && s.noiseEnabled && !opaque,
          ),
          child: content,
        ),
      );
    }
    if (blur) {
      ui.ImageFilter filter = ui.ImageFilter.blur(
        sigmaX: s.blurSigmaX.clamp(0, maxSigma),
        sigmaY: s.blurSigmaY.clamp(0, maxSigma),
      );
      if (s.saturation != 1 || s.contrast != 1) {
        final sat = s.saturation, c = s.contrast;
        final r = .2126 * (1 - sat),
            g = .7152 * (1 - sat),
            b = .0722 * (1 - sat);
        final shift = 128 * (1 - c);
        filter = ui.ImageFilter.compose(
          outer: ColorFilter.matrix([
            (r + sat) * c,
            g * c,
            b * c,
            0,
            shift,
            r * c,
            (g + sat) * c,
            b * c,
            0,
            shift,
            r * c,
            g * c,
            (b + sat) * c,
            0,
            shift,
            0,
            0,
            0,
            1,
            0,
          ]),
          inner: filter,
        );
      }
      final group = context.dependOnInheritedWidgetOfExactType<GlassGroup>();
      final nested =
          context.dependOnInheritedWidgetOfExactType<_SurfaceScope>() != null;
      final grouped =
          group != null &&
          !group.overlapping &&
          !nested &&
          performance.groupBackdropFilters &&
          s.blurSigmaX.clamp(0, maxSigma) ==
              groupStyle.blurSigmaX.clamp(0, maxSigma) &&
          s.blurSigmaY.clamp(0, maxSigma) ==
              groupStyle.blurSigmaY.clamp(0, maxSigma) &&
          s.saturation == groupStyle.saturation &&
          s.contrast == groupStyle.contrast;
      content = grouped
          ? BackdropFilter.grouped(filter: filter, child: content)
          : BackdropFilter(filter: filter, child: content);
    }
    // A backdrop must always be bounded, even when Clip.none is requested.
    final clip = clipBehavior == Clip.none ? Clip.hardEdge : clipBehavior;
    content = s.shape == BoxShape.circle
        ? ClipOval(clipBehavior: clip, child: content)
        : ClipRRect(
            borderRadius: s.borderRadius,
            clipBehavior: clip,
            child: content,
          );
    content = _SurfaceScope(child: content);
    content = Container(
      width: width,
      height: height,
      constraints: constraints,
      decoration:
          enabled &&
              performance.enableShadows &&
              !highContrast &&
              s.shadowOpacity > 0
          ? BoxDecoration(
              shape: s.shape,
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: s.shadowColor.withValues(
                    alpha: s.shadowColor.a * s.shadowOpacity,
                  ),
                  blurRadius: s.shadowBlurRadius,
                  offset: s.shadowOffset,
                ),
              ],
            )
          : null,
      child: content,
    );
    return Padding(padding: margin ?? EdgeInsets.zero, child: content);
  }
}

class _SurfaceScope extends InheritedWidget {
  const _SurfaceScope({required super.child});
  @override
  bool updateShouldNotify(_SurfaceScope oldWidget) => false;
}

class _GlassPainter extends CustomPainter {
  _GlassPainter(this.style, {required this.highContrast, required this.noise});
  final GlassStyle style;
  final bool highContrast, noise;
  @override
  void paint(Canvas canvas, Size size) {
    final s = style;
    final rect = Offset.zero & size;
    if (rect.isEmpty) return;
    // Foreground effects are confined to the rim, preserving text contrast.
    final stroke = math.min(
      highContrast ? math.max(2.0, s.borderWidth) : s.borderWidth,
      math.min(size.width, size.height) / 2,
    );
    if (stroke > 0) {
      final innerRect = rect.deflate(stroke / 2);
      final path = Path();
      if (s.shape == BoxShape.circle) {
        path.addOval(innerRect);
      } else {
        path.addRRect(s.borderRadius.toRRect(rect).deflate(stroke / 2));
      }
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = s.borderColor.withValues(
          alpha: highContrast ? 1 : s.borderColor.a * s.borderOpacity,
        );
      if (!highContrast && s.borderGradient != null)
        paint.shader = s.borderGradient!.createShader(rect);
      canvas.drawPath(path, paint);
      if (!highContrast && s.highlightOpacity > 0) {
        final direction = Alignment(
          math.cos(s.highlightAngle),
          math.sin(s.highlightAngle),
        );
        paint.shader = LinearGradient(
          begin: direction,
          end: -direction,
          colors: [
            s.highlightColor.withValues(
              alpha: s.highlightColor.a * s.highlightOpacity,
            ),
            s.highlightColor.withValues(alpha: 0),
          ],
        ).createShader(rect);
        canvas.drawPath(path, paint);
      }
    }
    if (noise && s.noiseOpacity > 0) {
      final random = math.Random(17);
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: s.noiseOpacity);
      // Fixed seed and bounded work: no textures, timers, or animated noise.
      final count = math.min(1600, (size.width * size.height / 160).round());
      for (var i = 0; i < count; i++) {
        canvas.drawCircle(
          Offset(
            random.nextDouble() * size.width,
            random.nextDouble() * size.height,
          ),
          .55,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GlassPainter oldDelegate) =>
      oldDelegate.style != style ||
      oldDelegate.highContrast != highContrast ||
      oldDelegate.noise != noise;
}
