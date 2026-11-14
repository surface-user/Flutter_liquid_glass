import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass_component_lab/main.dart';
import 'package:glass_component_lab/editor_catalog.dart';

void main() {
  testWidgets(
    'catalog uses two columns, real categories and searchable collapsed items',
    (tester) async {
      String? added;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 280,
              child: BasicPalette(onAdd: (type) => added = type),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.byKey(const ValueKey('basic-add-GlassButton'));
      final icon = find.byKey(const ValueKey('basic-add-GlassIconButton'));
      final left = tester.getTopLeft(button).dx;
      expect(tester.getTopLeft(button).dy, tester.getTopLeft(icon).dy);
      expect(
        tester.getTopLeft(icon).dx,
        greaterThan(tester.getTopLeft(button).dx + 50),
      );
      expect(find.text('FAB'), findsNothing);
      expect(find.text('玻璃表面'), findsNothing);
      expect(find.byKey(const ValueKey('basic-add-GlassCard')), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('basic-catalog-search')),
        '卡片',
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('basic-add-GlassCard'))).dx,
        left,
      );
      await tester.tap(find.byKey(const ValueKey('basic-add-GlassCard')));
      expect(added, 'GlassCard');
      await tester.enterText(
        find.byKey(const ValueKey('basic-catalog-search')),
        '没有这样的组件',
      );
      await tester.pumpAndSettle();
      expect(find.text('没有找到匹配内容'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'rail collapses and restores the panel and layers select without changing design',
    (tester) async {
      tester.view.physicalSize = const Size(1500, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const GlassLab());
      await tester.pumpAndSettle();
      final state = tester.state(find.byType(GlassLab)) as dynamic;
      final before = jsonEncode(state.scene);
      await tester.tap(find.byTooltip('收起组件面板'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('basic-catalog-search')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('nav-components')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('basic-catalog-search')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('nav-layers')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('layer-node-2')));
      await tester.pumpAndSettle();
      expect(state.selected, 'node-2');
      expect(state.global, isFalse);
      expect(jsonEncode(state.scene), before);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('catalog drag still adds an actual canvas component', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const GlassLab());
    await tester.pumpAndSettle();
    final state = tester.state(find.byType(GlassLab)) as dynamic;
    final count = state.modules.length as int;
    final tile = find.byKey(const ValueKey('basic-add-GlassIconButton'));
    final start = tester.getCenter(tile);
    final anchor = start - tester.getTopLeft(tile);
    await tester.dragFrom(start, const Offset(900, 500) - start);
    await tester.pumpAndSettle();
    expect(state.modules.length, count + 1);
    expect(state.modules.last['type'], 'GlassIconButton');
    final position = tester.getTopLeft(
      find.byKey(ValueKey(state.modules.last['id'] as String)),
    );
    expect(position.dx, closeTo(900 - anchor.dx, 8));
    expect(position.dy, closeTo(500 - anchor.dy, 8));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('drop positions follow canvas zoom and stay within the board', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final zoom in [.4, 1.25]) {
      await tester.pumpWidget(const GlassLab());
      await tester.pumpAndSettle();
      final state = tester.state(find.byType(GlassLab)) as dynamic;
      state.setState(() => state.zoom = zoom);
      await tester.pumpAndSettle();
      final tile = find.byKey(const ValueKey('basic-add-GlassButton'));
      final start = tester.getCenter(tile);
      final anchor = start - tester.getTopLeft(tile);
      await tester.dragFrom(start, const Offset(600, 350) - start);
      await tester.pumpAndSettle();
      final position = tester.getTopLeft(
        find.byKey(ValueKey(state.modules.last['id'] as String)),
      );
      expect(position.dx, closeTo(600 - anchor.dx, 8 * zoom + .1));
      expect(position.dy, closeTo(350 - anchor.dy, 8 * zoom + .1));
      final count = state.modules.length as int;
      state.add('GlassButton', at: const Offset(3000, -20));
      await tester.pumpAndSettle();
      expect(state.modules.length, count + 1);
      final last = state.modules.last;
      expect(last['x'] + last['w'], 1200);
      expect(last['y'], 0);
      expect(tester.takeException(), isNull, reason: '$zoom');
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets(
    'navigation search and add work at five widths and three Chinese font scales',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final width in [320.0, 390.0, 820.0, 1180.0, 1500.0]) {
        for (final scale in [1.0, 1.3, 2.0]) {
          tester.view.physicalSize = Size(width, 740);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          await tester.pumpWidget(const GlassLab());
          await tester.pumpAndSettle();
          if (width < 820) {
            await tester.tap(find.byKey(const ValueKey('nav-components')));
            await tester.pumpAndSettle();
          }
          final state = tester.state(find.byType(GlassLab)) as dynamic;
          final count = state.modules.length as int;
          await tester.enterText(
            find.byKey(const ValueKey('basic-catalog-search')),
            '按钮',
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('basic-add-GlassButton')));
          await tester.pumpAndSettle();
          expect(state.modules.length, count + 1);
          expect(state.modules.last['type'], 'GlassButton');
          if (width < 820)
            expect(
              find.byKey(const ValueKey('basic-catalog-search')),
              findsNothing,
            );
          expect(tester.takeException(), isNull, reason: '$width/$scale');
          await tester.pumpWidget(const SizedBox());
        }
      }
    },
  );
}
