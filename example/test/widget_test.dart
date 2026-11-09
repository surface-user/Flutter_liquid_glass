import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass_example/main.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

void main() {
  testWidgets('gallery reduced motion, dialog and navigation flow', (
    tester,
  ) async {
    await tester.pumpWidget(const GlassGallery());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Reduce motion'), 300);
    await tester.tap(find.text('Reduce motion'));
    await tester.pumpAndSettle();
    expect(
      LiquidGlassTheme.of(
        tester.element(find.text('Reduce motion')),
      ).accessibility.reduceMotion,
      isTrue,
    );
    await tester.scrollUntilVisible(find.text('Open glass dialog'), 300);
    await tester.tap(find.text('Open glass dialog'));
    await tester.pumpAndSettle();
    expect(find.byType(GlassDialog), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.byType(GlassDialog), findsNothing);
    await tester.scrollUntilVisible(find.text('Explore page transition'), 200);
    await tester.tap(find.text('Explore page transition'));
    await tester.pumpAndSettle();
    expect(find.text('Less motion. More meaning.'), findsOneWidget);
    await tester.tap(find.text('Back to the material lab'));
    await tester.pumpAndSettle();
    expect(find.text('Open glass dialog'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('gallery renders and theme switches', (tester) async {
    await tester.pumpWidget(const GlassGallery());
    expect(find.text('LIQUID / GLASS'), findsOneWidget);
    await tester.tap(find.byTooltip('Toggle theme'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final context = tester.element(find.text('LIQUID / GLASS'));
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
