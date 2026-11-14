import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass_component_lab/main.dart';
import 'package:glass_component_lab/registry.dart';
import 'package:glass_component_lab/workbench_preview.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

void main() {
  Future<dynamic> mount(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const GlassLab());
    await tester.pumpAndSettle();
    final state = tester.state(find.byType(GlassLab)) as dynamic;
    final item = module('GlassButton', 1, x: 200, y: 180)
      ..['w'] = 240
      ..['h'] = 96;
    item['props']['style'] = styleJson(GlassPresets.button)
      ..['borderRadius'] = 99;
    expect(state.commit(initialScene()..['modules'] = [item]), isNull);
    await tester.pumpAndSettle();
    return state;
  }

  testWidgets(
    'four edge grips touch the real button and resize each side at three zooms',
    (tester) async {
      final state = await mount(tester);
      for (final zoom in [.4, .85, 1.25]) {
        state.setState(() => state.zoom = zoom);
        await tester.pumpAndSettle();
        final frame = find.byKey(const ValueKey('node-1'));
        final button = find.descendant(
          of: frame,
          matching: find.byType(GlassButton),
        );
        expect(tester.getSize(button), const Size(240, 96));
        final r = tester.getRect(button);
        final before = jsonEncode(state.scene);
        final shape =
            tester
                    .widget<DecoratedBox>(
                      find.byKey(const ValueKey('selection-node-1')),
                    )
                    .decoration
                as ShapeDecoration;
        expect(shape.shape, isA<RoundedRectangleBorder>());
        expect(
          (shape.shape as RoundedRectangleBorder).borderRadius,
          BorderRadius.circular(99),
        );
        for (final side in ['left', 'right', 'top', 'bottom']) {
          final grip = find.byKey(ValueKey('resize-$side-node-1'));
          final expected = switch (side) {
            'left' => r.centerLeft,
            'right' => r.centerRight,
            'top' => r.topCenter,
            _ => r.bottomCenter,
          };
          expect((tester.getCenter(grip) - expected).distance, lessThan(.1));
          final delta = side == 'left' || side == 'right'
              ? Offset(24 * zoom, 0)
              : Offset(0, 16 * zoom);
          await tester.drag(grip, delta);
          await tester.pumpAndSettle();
          final resized = tester.getRect(button);
          switch (side) {
            case 'left':
              expect(resized.right, closeTo(r.right, .1));
              expect(resized.width, closeTo(r.width - delta.dx, .1));
            case 'right':
              expect(resized.left, closeTo(r.left, .1));
              expect(resized.width, closeTo(r.width + delta.dx, .1));
            case 'top':
              expect(resized.bottom, closeTo(r.bottom, .1));
              expect(resized.height, closeTo(r.height - delta.dy, .1));
            case 'bottom':
              expect(resized.top, closeTo(r.top, .1));
              expect(resized.height, closeTo(r.height + delta.dy, .1));
          }
          expect(tester.getSize(button), tester.getSize(frame));
          await tester.tap(find.byTooltip('撤销'));
          await tester.pumpAndSettle();
          expect(jsonEncode(state.scene), before);
        }
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'resize cancel restores geometry without history and minimum touch size is enforced',
    (tester) async {
      final state = await mount(tester);
      final before = jsonEncode(state.scene);
      final history = state.past.length;
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('resize-right-node-1'))),
      );
      await gesture.moveBy(const Offset(60, 0));
      await tester.pump();
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(jsonEncode(state.scene), before);
      expect(state.past.length, history);
      await tester.drag(
        find.byKey(const ValueKey('resize-left-node-1')),
        const Offset(600, 0),
      );
      await tester.pumpAndSettle();
      expect(state.modules.first['w'], 48);
      expect(tester.getSize(find.byType(GlassButton).first).width, 48);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'run preview uses the same real button dimensions without the old title offset',
    (tester) async {
      final scene = initialScene()
        ..['modules'] = [
          module('GlassButton', 1, x: 40, y: 80)
            ..['w'] = 220
            ..['h'] = 80,
        ];
      final before = jsonEncode(scene);
      await tester.pumpWidget(
        MaterialApp(home: WorkbenchPreview(scene: scene)),
      );
      await tester.pumpAndSettle();
      final button = find.byType(GlassButton);
      expect(tester.getSize(button), const Size(220, 80));
      final positioned = tester
          .widgetList<Positioned>(
            find.ancestor(of: button, matching: find.byType(Positioned)),
          )
          .where((p) => p.left == 40)
          .single;
      expect(positioned.top, 80);
      expect(positioned.height, 80);
      expect(jsonEncode(scene), before);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
