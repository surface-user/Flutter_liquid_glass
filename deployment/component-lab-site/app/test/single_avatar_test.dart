import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass_component_lab/main.dart';
import 'package:glass_component_lab/registry.dart';

void main() {
  testWidgets(
    'moving hides the whole original including selection while keeping its state and cancel restores it',
    (tester) async {
      tester.view.physicalSize = const Size(1500, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final advanced in [false, true]) {
        await tester.pumpWidget(GlassLab(initialAdvanced: advanced));
        await tester.pumpAndSettle();
        final state = tester.state(find.byType(GlassLab)) as dynamic;
        expect(
          state.commit(
            initialScene()
              ..['modules'] = [module('GlassButton', 1, x: 200, y: 180)],
          ),
          isNull,
        );
        await tester.pumpAndSettle();
        final before = jsonEncode(state.scene);
        final frame = find.byKey(const ValueKey('node-1'));
        final original = tester.element(frame);
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(const ValueKey('header-node-1'))),
        );
        await gesture.moveBy(const Offset(40, 30));
        await tester.pumpAndSettle();
        final selection = find.byKey(const ValueKey('selection-node-1'));
        final shell = find.byKey(const ValueKey('shell-node-1'));
        final hiding = find
            .descendant(of: shell, matching: find.byType(Opacity))
            .first;
        expect(tester.widget<Opacity>(hiding).opacity, 0);
        expect(find.ancestor(of: selection, matching: hiding), findsOneWidget);
        expect(
          find.ancestor(
            of: find.byKey(const ValueKey('resize-right-node-1')),
            matching: hiding,
          ),
          findsOneWidget,
        );
        expect(tester.element(frame), same(original));
        expect(
          find.byKey(const ValueKey('canvas-drag-feedback')),
          findsOneWidget,
        );
        await gesture.cancel();
        await tester.pumpAndSettle();
        expect(tester.widget<Opacity>(hiding).opacity, 1);
        expect(jsonEncode(state.scene), before);
        expect(
          find.byKey(const ValueKey('canvas-drag-feedback')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    },
  );
}
