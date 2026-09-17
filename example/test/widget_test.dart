import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass_example/main.dart';

void main() {
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
