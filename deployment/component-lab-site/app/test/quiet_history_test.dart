import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass_component_lab/main.dart';

void main() {
  testWidgets(
    'compact history icons remain beside preview at narrow widths and large Chinese text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final width in [320.0, 390.0, 820.0, 1180.0, 1500.0]) {
        for (final scale in [1.0, 2.0]) {
          tester.view.physicalSize = Size(width, 1000);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          await tester.pumpWidget(const GlassLab());
          await tester.pumpAndSettle();
          final state = tester.state(find.byType(GlassLab)) as dynamic;
          final history = find.byKey(const ValueKey('history-controls'));
          final undo = find.widgetWithIcon(IconButton, Icons.undo);
          final redo = find.widgetWithIcon(IconButton, Icons.redo);
          expect(undo.hitTestable(), findsOneWidget);
          expect(redo.hitTestable(), findsOneWidget);
          expect(tester.widget<IconButton>(undo).onPressed, isNull);
          expect(tester.widget<IconButton>(redo).onPressed, isNull);
          final preview = tester.getRect(
            find.byKey(const ValueKey('run-preview')),
          );
          final rect = tester.getRect(history);
          expect(preview.left - rect.right, inInclusiveRange(0, 12));
          expect((preview.center.dy - rect.center.dy).abs(), lessThan(1));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(preview.right, lessThanOrEqualTo(width));
          state.add('GlassButton');
          await tester.pumpAndSettle();
          final count = state.modules.length;
          await tester.tap(undo);
          await tester.pumpAndSettle();
          expect(state.modules.length, count - 1);
          await tester.tap(redo);
          await tester.pumpAndSettle();
          expect(state.modules.length, count);
          expect(find.byType(SnackBar), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        }
      }
    },
  );
}
