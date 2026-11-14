import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass_component_lab/main.dart';
import 'package:glass_component_lab/registry.dart';

void main() {
  Future<dynamic> mount(
    WidgetTester tester, {
    double width = 1500,
    double scale = 1,
    bool input = false,
  }) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const GlassLab());
    await tester.pumpAndSettle();
    final state = tester.state(find.byType(GlassLab)) as dynamic;
    final scene = initialScene()
      ..['modules'] = [
        module(input ? 'GlassTextField' : 'GlassButton', 1, x: 40, y: 40),
      ];
    if (input) scene['modules'][0]['props']['text'] = '保留的中文初值';
    expect(state.commit(scene), isNull);
    await tester.pumpAndSettle();
    return state;
  }

  testWidgets(
    'drop in the sidebar deletes only on release and undo restores the original design',
    (tester) async {
      final state = await mount(tester);
      final before = jsonEncode(state.scene);
      final history = state.past.length;
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('header-node-1'))),
      );
      await gesture.moveTo(const Offset(180, 450));
      await tester.pumpAndSettle();
      expect(find.text('松开即可删除'), findsOneWidget);
      expect(find.byKey(const ValueKey('delete-zone')), findsOneWidget);
      expect(state.modules.length, 1);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(state.modules, isEmpty);
      expect(state.past.length, history + 1);
      expect(find.byKey(const ValueKey('delete-zone')), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      await tester.tap(find.byTooltip('撤销'));
      await tester.pumpAndSettle();
      expect(jsonEncode(state.scene), before);
      await tester.tap(find.byTooltip('重做'));
      await tester.pumpAndSettle();
      expect(state.modules, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('cancel or leave the delete zone keeps the component', (
    tester,
  ) async {
    final state = await mount(tester);
    final before = jsonEncode(state.scene);
    final history = state.past.length;
    final start = tester.getCenter(find.byKey(const ValueKey('header-node-1')));
    var gesture = await tester.startGesture(start);
    await gesture.moveTo(const Offset(180, 450));
    await tester.pumpAndSettle();
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(jsonEncode(state.scene), before);
    expect(state.past.length, history);
    expect(find.byKey(const ValueKey('delete-zone')), findsNothing);
    gesture = await tester.startGesture(start);
    await gesture.moveTo(const Offset(180, 450));
    await tester.pumpAndSettle();
    await gesture.moveTo(start + const Offset(50, 40));
    await tester.pumpAndSettle();
    expect(state.overDelete, isFalse);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(state.modules.length, 1);
    expect(find.text('组件已删除'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'narrow large-text deletion releases input resources and header undo remains available',
    (tester) async {
      final state = await mount(tester, width: 390, scale: 2, input: true);
      final before = jsonEncode(state.scene);
      expect(state.runtime.controllers.length, 1);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('header-node-1'))),
      );
      await gesture.moveTo(const Offset(32, 450));
      await tester.pumpAndSettle();
      expect(find.text('删除'), findsOneWidget);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(state.modules, isEmpty);
      expect(state.runtime.controllers, isEmpty);
      expect(find.byType(SnackBar), findsNothing);
      await tester.tap(find.byTooltip('撤销'));
      await tester.pumpAndSettle();
      expect(jsonEncode(state.scene), before);
      expect(state.runtime.controllers.length, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
