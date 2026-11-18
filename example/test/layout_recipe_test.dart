import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass_example/recipes/layout_recipe.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

void main() {
  for (final blurEnabled in [true, false]) {
    testWidgets(
      'the same cards use a solid or glass panel (blur: $blurEnabled)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              extensions: [
                LiquidGlassThemeData(
                  performance: GlassPerformanceConfig(blurEnabled: blurEnabled),
                ),
              ],
            ),
            home: const LayoutRecipe(),
          ),
        );
        final cards = find.byType(Card);
        final panel = find.byType(GlassSurface);
        final filter = find.byType(BackdropFilter);
        expect(cards, findsNWidgets(2));
        expect(panel, findsNothing);
        expect(filter, findsNothing);
        final cardSizes = [for (final card in cards.evaluate()) card.size];

        await tester.tap(find.text('Use glass'));
        await tester.pumpAndSettle();
        expect(find.descendant(of: panel, matching: cards), findsNWidgets(2));
        expect(filter, blurEnabled ? findsOneWidget : findsNothing);
        expect([for (final card in cards.evaluate()) card.size], cardSizes);
        expect(find.text('Projects'), findsOneWidget);
        expect(find.text('Recent notes'), findsOneWidget);

        await tester.tap(find.text('Use solid'));
        await tester.pumpAndSettle();
        expect(cards, findsNWidgets(2));
        expect(panel, findsNothing);
        expect(filter, findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('narrow RTL layout wraps the header at 2x and scrolls to cards', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 440);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
        ),
        home: const LayoutRecipe(),
      ),
    );

    final title = find.text('A workspace layout for projects and recent notes');
    final action = find.byType(OutlinedButton);
    final titleContext = tester.element(title);
    expect(Directionality.of(titleContext), TextDirection.rtl);
    expect(MediaQuery.textScalerOf(titleContext).scale(20), 40);
    expect(tester.getSize(title).width, lessThanOrEqualTo(288));
    expect(
      tester.getTopLeft(action).dy,
      greaterThan(tester.getBottomLeft(title).dy),
    );
    expect(tester.getTopRight(action).dx, closeTo(304, 0.1));

    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    expect(action.hitTestable(), findsOneWidget);
    await tester.tap(find.text('Use glass'));
    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsOneWidget);

    final lastTitle = find.text('Recent notes');
    await tester.scrollUntilVisible(lastTitle, 100);
    await tester.pumpAndSettle();
    expect(tester.getBottomRight(lastTitle).dy, lessThanOrEqualTo(440));
    expect(tester.takeException(), isNull);
  });
}
