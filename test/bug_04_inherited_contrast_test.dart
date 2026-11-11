import 'dart:ui' show ColorSpace;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

Widget _scene({
  required Brightness brightness,
  required bool highContrast,
  bool system = false,
  TextStyle? body,
  TextStyle? headline,
  TextStyle? title,
  AppBarThemeData? appBarTheme,
  String role = 'body',
}) => MaterialApp(
  theme: ThemeData(
    platform: TargetPlatform.windows,
    brightness: brightness,
    textTheme: TextTheme(
      bodyMedium: body,
      headlineSmall: headline,
      titleLarge: title,
    ),
    appBarTheme: appBarTheme,
    extensions: [
      (brightness == Brightness.dark
              ? LiquidGlassThemeData.dark()
              : const LiquidGlassThemeData())
          .copyWith(
            accessibility: GlassAccessibilityConfig(
              highContrast: highContrast && !system,
            ),
          ),
    ],
  ),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(highContrast: highContrast && system),
    child: child!,
  ),
  home: Scaffold(
    appBar: role == 'appbar'
        ? const GlassAppBar(title: Text('Inherited content'))
        : null,
    body: role == 'dialog'
        ? const GlassDialog(
            title: Text('Inherited content'),
            content: SizedBox(width: 80, height: 30),
          )
        : role == 'appbar'
        ? null
        : const GlassCard(child: Text('Inherited content')),
  ),
);

TextStyle _contentStyle(WidgetTester tester) =>
    DefaultTextStyle.of(tester.element(find.text('Inherited content'))).style;

Color _foreground(TextStyle style) => style.foreground?.color ?? style.color!;

double _contrast(Color foreground, Color background) {
  final front = Color.alphaBlend(foreground, background).computeLuminance();
  final back = background.computeLuminance();
  return front > back
      ? (front + .05) / (back + .05)
      : (back + .05) / (front + .05);
}

void main() {
  for (final brightness in Brightness.values) {
    final dark = brightness == Brightness.dark;
    final background = dark ? const Color(0xff202a3c) : const Color(0xffedf1f8);
    final unreadable = dark ? Colors.black : Colors.white;
    for (final system in [false, true]) {
      testWidgets(
        'inherited text stays readable / $brightness / system $system',
        (tester) async {
          for (final color in [
            unreadable,
            (dark ? Colors.white : Colors.black).withValues(alpha: .05),
            unreadable.withValues(colorSpace: ColorSpace.displayP3),
            unreadable.withValues(colorSpace: ColorSpace.extendedSRGB),
          ]) {
            Widget scene(bool enabled) => _scene(
              brightness: brightness,
              highContrast: enabled,
              system: system,
              body: TextStyle(
                color: color,
                fontSize: 19,
                fontWeight: FontWeight.w500,
              ),
            );
            await tester.pumpWidget(scene(false));
            await tester.pumpAndSettle();
            expect(
              _foreground(_contentStyle(tester)).toARGB32(),
              color.toARGB32(),
            );
            await tester.pumpWidget(scene(true));
            await tester.pumpAndSettle();
            final effective = _contentStyle(tester);
            expect(
              _contrast(_foreground(effective), background),
              greaterThanOrEqualTo(4.5),
            );
            expect(effective.fontSize, 19);
            expect(effective.fontWeight, FontWeight.w500);
            await tester.pumpWidget(scene(false));
            await tester.pumpAndSettle();
            expect(
              _foreground(_contentStyle(tester)).toARGB32(),
              color.toARGB32(),
            );
          }
        },
      );
    }

    testWidgets('readable legacy text is unchanged / $brightness', (
      tester,
    ) async {
      for (final role in ['body', 'dialog', 'appbar']) {
        await tester.pumpWidget(
          _scene(brightness: brightness, highContrast: false, role: role),
        );
        await tester.pumpAndSettle();
        final ordinary = _contentStyle(tester);
        await tester.pumpWidget(
          _scene(brightness: brightness, highContrast: true, role: role),
        );
        await tester.pumpAndSettle();
        final accessible = _contentStyle(tester);
        expect(
          _foreground(accessible).toARGB32(),
          _foreground(ordinary).toARGB32(),
        );
        expect(
          _contrast(_foreground(accessible), background),
          greaterThanOrEqualTo(4.5),
        );
        expect(accessible.foreground, ordinary.foreground);
      }
    });

    testWidgets('inherited Paint cannot bypass high contrast / $brightness', (
      tester,
    ) async {
      final shader = const LinearGradient(
        colors: [Colors.white, Colors.black],
      ).createShader(const Rect.fromLTWH(0, 0, 100, 30));
      final paint = Paint()
        ..color = unreadable
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      Widget scene(bool enabled) => _scene(
        brightness: brightness,
        highContrast: enabled,
        body: TextStyle(foreground: paint),
      );
      await tester.pumpWidget(scene(false));
      await tester.pumpAndSettle();
      expect(_contentStyle(tester).foreground?.shader, same(shader));
      await tester.pumpWidget(scene(true));
      await tester.pumpAndSettle();
      final accessible = _contentStyle(tester);
      expect(
        _contrast(_foreground(accessible), background),
        greaterThanOrEqualTo(4.5),
      );
      expect(accessible.foreground?.shader, isNull);
      expect(accessible.foreground?.style, PaintingStyle.fill);
      expect(paint.shader, same(shader));
      expect(paint.style, PaintingStyle.stroke);
      expect(paint.strokeWidth, 3);
      expect(paint.color.toARGB32(), unreadable.toARGB32());
      await tester.pumpWidget(scene(false));
      await tester.pumpAndSettle();
      expect(_contentStyle(tester).foreground?.shader, same(shader));
      expect(_contentStyle(tester).foreground?.style, PaintingStyle.stroke);
    });

    testWidgets('title roles use their actual inherited style / $brightness', (
      tester,
    ) async {
      for (final role in ['dialog', 'appbar', 'appbarForeground']) {
        final paint = Paint()
          ..color = unreadable
          ..style = PaintingStyle.stroke;
        final inherited = TextStyle(
          foreground: paint,
          fontSize: 27,
          fontWeight: FontWeight.w700,
        );
        Widget scene(bool enabled) => _scene(
          brightness: brightness,
          highContrast: enabled,
          role: role == 'appbarForeground' ? 'appbar' : role,
          headline: role == 'dialog' ? inherited : null,
          appBarTheme: role == 'appbar'
              ? AppBarThemeData(titleTextStyle: inherited)
              : role == 'appbarForeground'
              ? AppBarThemeData(foregroundColor: unreadable)
              : null,
        );
        await tester.pumpWidget(scene(false));
        await tester.pumpAndSettle();
        expect(
          _foreground(_contentStyle(tester)).toARGB32(),
          unreadable.toARGB32(),
        );
        await tester.pumpWidget(scene(true));
        await tester.pumpAndSettle();
        final accessible = _contentStyle(tester);
        expect(
          _contrast(_foreground(accessible), background),
          greaterThanOrEqualTo(4.5),
        );
        if (role != 'appbarForeground') {
          expect(accessible.fontSize, 27);
          expect(accessible.fontWeight, FontWeight.w700);
          expect(accessible.foreground?.style, PaintingStyle.fill);
        }
        expect(paint.style, PaintingStyle.stroke);
        expect(paint.color.toARGB32(), unreadable.toARGB32());
      }
    });
  }
}
