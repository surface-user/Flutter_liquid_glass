import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'high contrast replaces caller Paint without mutation / $brightness',
      (tester) async {
        final dark = brightness == Brightness.dark;
        final originalColor = dark ? Colors.black : Colors.white;
        final shader = const LinearGradient(
          colors: [Colors.red, Colors.blue],
        ).createShader(const Rect.fromLTWH(0, 0, 80, 20));
        final paint = Paint()
          ..color = originalColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..shader = shader;
        Widget scene(bool highContrast) => MaterialApp(
          theme: ThemeData(
            brightness: brightness,
            platform: TargetPlatform.windows,
            extensions: [
              (dark
                      ? LiquidGlassThemeData.dark()
                      : const LiquidGlassThemeData())
                  .copyWith(
                    accessibility: GlassAccessibilityConfig(
                      highContrast: highContrast,
                    ),
                  ),
            ],
          ),
          home: Scaffold(
            body: GlassTextField(
              style: TextStyle(
                foreground: paint,
                fontSize: 23,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.25,
              ),
            ),
          ),
        );
        TextStyle inputStyle() =>
            tester.widget<EditableText>(find.byType(EditableText)).style;

        await tester.pumpWidget(scene(false));
        expect(inputStyle().foreground, same(paint));
        await tester.pumpWidget(scene(true));
        await tester.pumpAndSettle();
        final accessible = inputStyle();
        expect(accessible.foreground, isNot(same(paint)));
        expect(
          accessible.foreground!.color.toARGB32(),
          (dark ? Colors.white : const Color(0xff17233b)).toARGB32(),
        );
        expect(accessible.foreground!.shader, isNull);
        expect(accessible.foreground!.style, PaintingStyle.fill);
        expect(accessible.fontSize, 23);
        expect(accessible.fontWeight, FontWeight.w700);
        expect(accessible.letterSpacing, 1.25);
        expect(paint.color, originalColor);
        expect(paint.shader, same(shader));
        expect(paint.style, PaintingStyle.stroke);
        expect(paint.strokeWidth, 3);

        await tester.pumpWidget(scene(false));
        await tester.pumpAndSettle();
        expect(inputStyle().foreground, same(paint));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
