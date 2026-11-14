import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass_component_lab/main.dart';
import 'package:glass_component_lab/drag_preview.dart';
import 'package:glass_component_lab/registry.dart';

void main() {
  Future<dynamic> mount(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const GlassLab());
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
    return state;
  }

  testWidgets(
    'existing component follows the pointer across the page and deletion appears only inside the sidebar',
    (tester) async {
      final state = await mount(tester);
      final before = jsonEncode(state.scene);
      final history = state.past.length;
      final source = find.byKey(const ValueKey('header-node-1'));
      await tester.tap(source);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('delete-zone')), findsNothing);
      final start = tester.getCenter(source);
      final initial = tester.getTopLeft(find.byKey(const ValueKey('node-1')));
      final gesture = await tester.startGesture(start);
      await gesture.moveBy(const Offset(35, 25));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('delete-zone')), findsNothing);
      final feedback = find.byKey(const ValueKey('canvas-drag-feedback'));
      expect(feedback, findsOneWidget);
      await gesture.moveTo(const Offset(1450, 35));
      await tester.pumpAndSettle();
      final expected = initial + const Offset(1450, 35) - start;
      expect((tester.getTopLeft(feedback) - expected).distance, lessThan(1));
      expect(find.byKey(const ValueKey('delete-zone')), findsNothing);
      await gesture.moveTo(const Offset(180, 450));
      await tester.pumpAndSettle();
      expect(find.text('松开即可删除'), findsOneWidget);
      await gesture.moveTo(start + const Offset(60, 40));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('delete-zone')), findsNothing);
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(jsonEncode(state.scene), before);
      expect(state.past.length, history);
      expect(feedback, findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'catalog drag previews the component over the whole page and adds once at the actual drop point',
    (tester) async {
      final state = await mount(tester);
      final count = state.modules.length;
      final tile = find.byKey(const ValueKey('basic-add-GlassButton'));
      final gesture = await tester.startGesture(tester.getCenter(tile));
      await gesture.moveTo(const Offset(1450, 35));
      await tester.pumpAndSettle();
      final feedback = find.byKey(const ValueKey('catalog-drag-feedback'));
      expect(feedback, findsOneWidget);
      expect(
        (tester.getTopLeft(feedback) - const Offset(1434, 19)).distance,
        lessThan(1),
      );
      expect(state.modules.length, count);
      expect(find.byKey(const ValueKey('delete-zone')), findsNothing);
      await gesture.moveTo(const Offset(650, 450));
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(state.modules.length, count + 1);
      final position = tester.getTopLeft(
        find.byKey(ValueKey(state.modules.last['id'] as String)),
      );
      expect(position.dx, closeTo(634, 8 * state.zoom + .1));
      expect(position.dy, closeTo(434, 8 * state.zoom + .1));
      expect(feedback, findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'narrow catalog hides during dragging and preserves valid drop and cancel',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const GlassLab());
      await tester.pumpAndSettle();
      final state = tester.state(find.byType(GlassLab)) as dynamic;
      final count = state.modules.length;
      await tester.tap(find.byKey(const ValueKey('nav-components')));
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('basic-add-GlassButton'))),
      );
      await gesture.moveBy(const Offset(60, 0));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Opacity>(
              find
                  .ancestor(
                    of: find.byKey(const ValueKey('basic-catalog-search')),
                    matching: find.byType(Opacity),
                  )
                  .first,
            )
            .opacity,
        0,
      );
      expect(
        find.byKey(const ValueKey('catalog-drag-feedback')),
        findsOneWidget,
      );
      await gesture.moveTo(const Offset(280, 450));
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(state.modules.length, count + 1);
      expect(find.byType(DragPreview), findsNothing);
      final beforeCancel = jsonEncode(state.scene);
      await tester.tap(find.byKey(const ValueKey('nav-components')));
      await tester.pumpAndSettle();
      final canceled = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('basic-add-GlassButton'))),
      );
      await canceled.moveBy(const Offset(60, 0));
      await tester.pumpAndSettle();
      await canceled.moveTo(const Offset(280, 450));
      await tester.pumpAndSettle();
      await canceled.cancel();
      await tester.pumpAndSettle();
      expect(jsonEncode(state.scene), beforeCancel);
      expect(find.byType(DragPreview), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'avatar input resources are isolated, reduced motion updates dynamically and disposal stops tickers',
    (tester) async {
      final item = module('GlassTextField', 0)..['props']['autofocus'] = true;
      final theme = themeDefaults();
      Future<void> render(bool reduced) => tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: DragPreview(item: item, theme: theme),
          ),
        ),
      );
      await render(false);
      await tester.pump(const Duration(milliseconds: 20));
      final preview = tester.state(find.byType(DragPreview)) as dynamic;
      final runtime = preview.runtime as Runtime;
      expect(runtime.controllers.length, 1);
      final animation = find.byType(TweenAnimationBuilder<double>);
      expect(
        tester.widget<TweenAnimationBuilder<double>>(animation).duration,
        const Duration(milliseconds: 140),
      );
      await render(true);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TweenAnimationBuilder<double>>(animation).duration,
        Duration.zero,
      );
      expect(tester.binding.transientCallbackCount, 0);
      theme['accessibility']['reduceMotion'] = true;
      await render(false);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TweenAnimationBuilder<double>>(animation).duration,
        Duration.zero,
      );
      theme['accessibility']['reduceMotion'] = false;
      theme['performance']['enableAnimations'] = false;
      await render(false);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TweenAnimationBuilder<double>>(animation).duration,
        Duration.zero,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(
        () => runtime.controllers.values.single.addListener(() {}),
        throwsFlutterError,
      );
      expect(tester.binding.transientCallbackCount, 0);
    },
  );
}
