import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/bloom_painter.dart';
import '../../theme/theme.dart';

/// Procedural radial light blooms over a gradient. Requires bounded layout.
/// Optional animation translates a cached background; blur is never animated.
class GlassBackdrop extends StatefulWidget {
  const GlassBackdrop({
    super.key,
    this.child,
    this.gradient,
    this.intensity = 1,
    this.animate = false,
    this.colors = const [
      Color(0xff7a9fff),
      Color(0xffcfa5ee),
      Color(0xff70d8cf),
    ],
  }) : assert(intensity >= 0 && intensity <= 1);
  final Widget? child;
  final Gradient? gradient;
  final List<Color> colors;
  final double intensity;
  final bool animate;
  @override
  State<GlassBackdrop> createState() => _GlassBackdropState();
}

class _GlassBackdropState extends State<GlassBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  );
  void _sync() {
    if (widget.animate &&
        !glassReduceMotion(context) &&
        TickerMode.valuesOf(context).enabled) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(GlassBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = LiquidGlassTheme.of(context).brightness == Brightness.dark;
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient:
                  widget.gradient ??
                  LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: dark
                        ? const [Color(0xff091421), Color(0xff25223b)]
                        : const [Color(0xffedf4fb), Color(0xffe7e9f7)],
                  ),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: GlassBloomPainter(
                  List<Color>.of(widget.colors),
                  widget.intensity * (dark ? .45 : .8),
                ),
              ),
            ),
            builder: (context, child) => Transform.translate(
              offset: Offset(
                math.sin(_controller.value * math.pi) * 12,
                _controller.value * 16,
              ),
              child: child,
            ),
          ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}
