import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

Widget _host(
  Widget child, {
  LiquidGlassThemeData glass = const LiquidGlassThemeData(),
}) => MaterialApp(
  theme: ThemeData(platform: TargetPlatform.windows, extensions: [glass]),
  home: Scaffold(body: Center(child: child)),
);

Material _buttonMaterial(WidgetTester tester) => tester.widget<Material>(
  find.descendant(of: find.byType(TextButton), matching: find.byType(Material)),
);

void main() {
  testWidgets('selected desktop SDK properties track controlled selection', (
    tester,
  ) async {
    var selected = false;
    late StateSetter rebuild;
    WidgetStateProperty<T> value<T>(T normal, T active) =>
        WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? active : normal,
        );
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return GlassNavigationItem(
              label: 'Stateful item',
              leading: const Icon(Icons.folder),
              selected: selected,
              onPressed: () {},
              controlStyle: ButtonStyle(
                shape: value<OutlinedBorder>(
                  const RoundedRectangleBorder(),
                  const StadiumBorder(),
                ),
                iconColor: value(Colors.blue, Colors.red),
                shadowColor: value(Colors.green, Colors.purple),
                surfaceTintColor: value(Colors.orange, Colors.yellow),
                elevation: value(1.0, 5.0),
                fixedSize: value(const Size(150, 48), const Size(210, 64)),
                mouseCursor: value<MouseCursor>(
                  SystemMouseCursors.click,
                  SystemMouseCursors.grab,
                ),
              ),
            );
          },
        ),
      ),
    );
    for (final active in [false, true, false]) {
      rebuild(() => selected = active);
      await tester.pumpAndSettle();
      final material = _buttonMaterial(tester);
      expect(
        material.shape,
        active ? isA<StadiumBorder>() : isA<RoundedRectangleBorder>(),
      );
      expect(material.elevation, active ? 5 : 1);
      expect(material.shadowColor, active ? Colors.purple : Colors.green);
      expect(material.surfaceTintColor, active ? Colors.yellow : Colors.orange);
      expect(
        tester.getSize(find.byType(TextButton)),
        active ? const Size(210, 64) : const Size(150, 48),
      );
      expect(
        IconTheme.of(tester.element(find.byIcon(Icons.folder))).color,
        active ? Colors.red : Colors.blue,
      );
      expect(
        tester
            .widgetList<MouseRegion>(
              find.descendant(
                of: find.byType(TextButton),
                matching: find.byType(MouseRegion),
              ),
            )
            .any(
              (region) =>
                  region.cursor ==
                  (active ? SystemMouseCursors.grab : SystemMouseCursors.click),
            ),
        isTrue,
      );
    }
  });

  testWidgets('selected desktop maximum size constrains a long title', (
    tester,
  ) async {
    for (final selected in [false, true]) {
      await tester.pumpWidget(
        _host(
          GlassNavigationItem(
            label: 'Long navigation title ' * 20,
            selected: selected,
            onPressed: () {},
            controlStyle: ButtonStyle(
              maximumSize: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? const Size(180, 48)
                    : const Size(260, 48),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(TextButton)).width,
        selected ? 180 : 260,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'selected styles preserve theme state inheritance and accessibility',
    (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      final local = ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? null : Colors.red,
        ),
        iconColor: const WidgetStatePropertyAll(Colors.red),
        shape: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? const StadiumBorder()
              : const RoundedRectangleBorder(),
        ),
      );
      Widget scene(bool contrast) => _host(
        GlassNavigationItem(
          label: 'Inherited selection',
          leading: const Icon(Icons.folder),
          selected: true,
          focusNode: focus,
          onPressed: () {},
          controlStyle: local,
        ),
        glass: LiquidGlassThemeData(
          controlStyle: const ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(Colors.green),
          ),
          accessibility: GlassAccessibilityConfig(
            highContrast: contrast,
            reduceMotion: true,
          ),
        ),
      );
      await tester.pumpWidget(scene(false));
      await tester.pumpAndSettle();
      expect(
        DefaultTextStyle.of(
          tester.element(find.text('Inherited selection')),
        ).style.color,
        Colors.green,
      );
      await tester.pumpWidget(scene(true));
      await tester.pumpAndSettle();
      focus.requestFocus();
      await tester.pumpAndSettle();
      final shape = _buttonMaterial(tester).shape! as StadiumBorder;
      expect(shape.side.width, 2);
      expect(shape.side.color, const Color(0xff17233b));
      expect(
        IconTheme.of(tester.element(find.byIcon(Icons.folder))).color,
        const Color(0xff17233b),
      );
      expect(
        tester
            .widget<TextButton>(find.byType(TextButton))
            .style!
            .animationDuration,
        Duration.zero,
      );
      expect(tester.binding.transientCallbackCount, 0);
    },
  );
}
