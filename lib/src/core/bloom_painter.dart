import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class GlassBloomPainter extends CustomPainter {
  GlassBloomPainter(this.colors, this.intensity);
  final List<Color> colors;
  final double intensity;
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < colors.length; i++) {
      final center = Offset(
        size.width * (.12 + (i * .37) % .8),
        size.height * (.18 + (i * .31) % .7),
      );
      final radius = size.longestSide * .52;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              colors[i].withValues(alpha: colors[i].a * intensity),
              colors[i].withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }
  }

  @override
  bool shouldRepaint(GlassBloomPainter oldDelegate) =>
      oldDelegate.intensity != intensity ||
      !listEquals(oldDelegate.colors, colors);
}
