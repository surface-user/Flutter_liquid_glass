import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass_component_lab/main.dart';
import 'package:glass_component_lab/registry.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

void main() {
  Future<dynamic> mount(WidgetTester tester, {bool advanced = false}) async {
    tester.view.physicalSize = const Size(1500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(GlassLab(initialAdvanced: advanced));
    await tester.pumpAndSettle();
    return tester.state(find.byType(GlassLab)) as dynamic;
  }

  testWidgets(
    'toolbar is flush with its frame and has no title strip in either editor',
    (tester) async {
      for (final advanced in [false, true]) {
        final state = await mount(tester, advanced: advanced);
        final scene = initialScene()
          ..['modules'] = [module('GlassToolbar', 1, x: 40, y: 40)];
        expect(state.commit(scene), isNull);
        await tester.pumpAndSettle();
        final frame = find.byKey(const ValueKey('node-1'));
        final toolbar = find.descendant(
          of: frame,
          matching: find.byType(GlassToolbar),
        );
        expect(
          find.descendant(of: frame, matching: find.text('工具栏')),
          findsNothing,
        );
        expect(tester.getTopLeft(toolbar), tester.getTopLeft(frame));
        expect(find.byKey(const ValueKey('selection-node-1')), findsOneWidget);
        final rect = tester.getRect(frame);
        await tester.tapAt(rect.bottomRight + const Offset(35, 35));
        await tester.pumpAndSettle();
        expect(state.selected, isNull);
        expect(find.byKey(const ValueKey('selection-node-1')), findsNothing);
        expect(find.byKey(const ValueKey('resize-node-1')), findsNothing);
        expect(find.byType(GlassToolbar), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    },
  );

  testWidgets(
    'content drag, resize and undo preserve interaction and design values',
    (tester) async {
      final state = await mount(tester);
      final scene = initialScene()
        ..['modules'] = [module('GlassButton', 1, x: 40, y: 40)];
      expect(state.commit(scene), isNull);
      await tester.pumpAndSettle();
      final frame = find.byKey(const ValueKey('node-1'));
      final original = jsonEncode(state.scene);
      final rect = tester.getRect(frame);
      await tester.drag(
        find.byKey(const ValueKey('header-node-1')),
        const Offset(85, 42),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(frame).left, greaterThan(rect.left + 60));
      expect(state.events, isEmpty);
      await tester.tap(find.byTooltip('撤销'));
      await tester.pumpAndSettle();
      expect(jsonEncode(state.scene), original);
      final size = tester.getSize(frame);
      await tester.drag(
        find.byKey(const ValueKey('resize-node-1')),
        const Offset(68, 34),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(frame).width, greaterThan(size.width + 60));
      await tester.tap(find.byTooltip('撤销'));
      await tester.pumpAndSettle();
      expect(jsonEncode(state.scene), original);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'surface can use all frame dimensions without hidden header overhead',
    (tester) async {
      final state = await mount(tester, advanced: true);
      final surface = module('GlassSurface', 1, x: 40, y: 40)
        ..['w'] = 120
        ..['h'] = 90
        ..['props']['width'] = 120
        ..['props']['height'] = 90;
      final scene = initialScene()..['modules'] = [surface];
      expect(requiredFrame(surface), const Size(120, 90));
      expect(state.commit(scene), isNull);
      await tester.pumpAndSettle();
      final actual = find
          .descendant(
            of: find.byKey(const ValueKey('node-1/root')),
            matching: find.byType(GlassSurface),
          )
          .first;
      expect(tester.getSize(actual), const Size(120, 90));
      expect(
        tester.getSize(find.byKey(const ValueKey('node-1'))),
        const Size(120, 90),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
