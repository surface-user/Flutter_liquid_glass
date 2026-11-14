import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass_component_lab/main.dart';
import 'package:glass_component_lab/registry.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

void main() {
  testWidgets(
    'natural controls have content bounds without empty resize frames',
    (tester) async {
      tester.view.physicalSize = const Size(1500, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const GlassLab());
      await tester.pumpAndSettle();
      final state = tester.state(find.byType(GlassLab)) as dynamic;
      for (final type in [
        'GlassTab',
        'GlassNavigationItem',
        'GlassMenu',
        'Text',
        'Icon',
      ]) {
        final item = module(type, 1, x: 40, y: 40);
        final scene = initialScene()..['modules'] = [item];
        expect(state.commit(scene), isNull);
        final original = jsonEncode(state.scene);
        await tester.pumpAndSettle();
        final frame = find.byKey(const ValueKey('node-1'));
        final content = find.byKey(const ValueKey('node-1/root'));
        expect(tester.getRect(frame), tester.getRect(content));
        final outline = find.byKey(const ValueKey('selection-node-1'));
        expect(tester.getRect(outline), tester.getRect(content));
        expect(tester.getSize(frame).height, lessThan(item['h']));
        expect(
          find.byKey(const ValueKey('resize-bottom-node-1')),
          findsNothing,
        );
        if (type == 'GlassTab') {
          final tab = find.byType(GlassTab);
          expect(tester.getRect(outline), tester.getRect(tab));
          final navigation = find.byType(GlassNavigationItem);
          final close = find.byTooltip('关闭: 未命名画布');
          expect(
            tester.getRect(outline).contains(tester.getCenter(navigation)),
            isTrue,
          );
          expect(
            tester.getRect(outline).contains(tester.getCenter(close)),
            isTrue,
          );
        }
        await tester.drag(
          find.byKey(const ValueKey('header-node-1')),
          const Offset(80, 40),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('撤销'));
        await tester.pumpAndSettle();
        expect(jsonEncode(state.scene), original);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
    },
  );
}
