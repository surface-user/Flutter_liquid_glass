import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';
import 'widget_test.dart' show host;

void main() {
  for (final mode in [
    'normal',
    'reduced',
    'contrast',
    'opaque',
    'low',
    'disabled',
  ]) {
    testWidgets('pointer rim repaints without rebuilding / $mode', (
      tester,
    ) async {
      const boundaryKey = ValueKey('pointer-scene');
      await tester.pumpWidget(
        host(
          RepaintBoundary(
            key: boundaryKey,
            child: GlassButton(
              onPressed: mode == 'disabled' ? null : () {},
              child: const SizedBox(width: 120, height: 40),
            ),
          ),
          theme: LiquidGlassThemeData(
            accessibility: GlassAccessibilityConfig(
              reduceMotion: mode == 'reduced',
              highContrast: mode == 'contrast',
              reduceTransparency: mode == 'opaque',
            ),
            performance: GlassPerformanceConfig(
              quality: mode == 'low' ? GlassQuality.low : GlassQuality.balanced,
            ),
          ),
        ),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(5, 5));
      final rect = tester.getRect(find.byType(GlassButton));
      await mouse.moveTo(rect.topLeft + const Offset(12, 8));
      await tester.pumpAndSettle();
      final paints = find.descendant(
        of: find.byType(GlassButton),
        matching: find.byType(CustomPaint),
      );
      final beforeWidgets = tester.widgetList<CustomPaint>(paints).toList();
      Future<List<int>> pixels() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(boundaryKey),
        );
        final image = await boundary.toImage();
        try {
          return (await image.toByteData())!.buffer.asUint8List().toList();
        } finally {
          image.dispose();
        }
      }

      final before = await tester.runAsync(pixels);
      await mouse.moveTo(rect.topRight + const Offset(-12, 8));
      await tester.pumpAndSettle();
      final after = await tester.runAsync(pixels);
      final afterWidgets = tester.widgetList<CustomPaint>(paints).toList();
      expect(listEquals(beforeWidgets, afterWidgets), isTrue);
      expect(listEquals(before, after), mode != 'normal');
      expect(tester.getRect(find.byType(GlassButton)).size, rect.size);
      await mouse.removePointer();
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
    });
  }
}
