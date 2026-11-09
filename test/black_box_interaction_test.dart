import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

const contentKey = ValueKey('content');
Widget subject(String kind, VoidCallback? action) {
  const child = SizedBox(key: contentKey, width: 100, height: 40);
  return switch (kind) {
    'card' => GlassCard(onTap: action, child: child),
    'icon' => GlassIconButton(onPressed: action, tooltip: 'Icon', icon: child),
    _ => GlassButton(onPressed: action, child: child),
  };
}

Widget app(Widget child, {int reduced = 0}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(
      disableAnimations: reduced == 1,
      accessibleNavigation: reduced == 2,
    ),
    child: LiquidGlassTheme(
      data: LiquidGlassThemeData(
        accessibility: GlassAccessibilityConfig(reduceMotion: reduced == 3),
        performance: GlassPerformanceConfig(enableAnimations: reduced != 4),
      ),
      child: Scaffold(body: Center(child: child)),
    ),
  ),
);
Rect painted(WidgetTester t) {
  final box = t.renderObject<RenderBox>(find.byKey(contentKey));
  return Rect.fromPoints(
    box.localToGlobal(Offset.zero),
    box.localToGlobal(box.size.bottomRight(Offset.zero)),
  );
}

void main() {
  for (final kind in ['button', 'icon', 'card']) {
    for (final ending in ['release', 'outside', 'cancel']) {
      testWidgets('$kind touch $ending restores geometry and idle', (t) async {
        var count = 0;
        await t.pumpWidget(app(subject(kind, () => count++)));
        await t.pumpAndSettle();
        final baseline = painted(t);
        final size = t.getSize(find.byKey(contentKey));
        final g = await t.startGesture(baseline.center);
        await t.pump();
        await t.pump(const Duration(milliseconds: 110));
        await t.pump(const Duration(milliseconds: 110));
        expect(painted(t).width / baseline.width, closeTo(.98, .001));
        expect(t.getSize(find.byKey(contentKey)), size);
        if (ending == 'outside') await g.moveTo(const Offset(5, 5));
        if (ending == 'cancel') {
          await g.cancel();
        } else {
          await g.up();
        }
        await t.pumpAndSettle();
        expect(painted(t), baseline);
        expect(count, ending == 'release' ? 1 : 0);
        expect(t.binding.transientCallbackCount, 0);
      });
    }
    testWidgets('$kind real mouse hover enter and leave', (t) async {
      await t.pumpWidget(app(subject(kind, () {})));
      final baseline = painted(t);
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(5, 5));
      await mouse.moveTo(baseline.center);
      await t.pumpAndSettle();
      expect(painted(t).width / baseline.width, closeTo(1.01, .001));
      await mouse.moveTo(const Offset(5, 5));
      await t.pumpAndSettle();
      expect(painted(t), baseline);
      expect(t.binding.transientCallbackCount, 0);
      await mouse.removePointer();
    });
    testWidgets('$kind keyboard Tab Enter Space activates', (t) async {
      var count = 0;
      await t.pumpWidget(app(subject(kind, () => count++)));
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pumpAndSettle();
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(count, 1);
      await t.sendKeyEvent(LogicalKeyboardKey.space);
      await t.pumpAndSettle();
      expect(count, 2);
    });
    testWidgets('$kind disabling during press cancels activation', (t) async {
      var enabled = true;
      var count = 0;
      late StateSetter update;
      await t.pumpWidget(
        app(
          StatefulBuilder(
            builder: (c, set) {
              update = set;
              return subject(kind, enabled ? () => count++ : null);
            },
          ),
        ),
      );
      final baseline = painted(t);
      final g = await t.startGesture(baseline.center);
      await t.pumpAndSettle();
      update(() => enabled = false);
      await t.pumpAndSettle();
      await g.up();
      await t.pumpAndSettle();
      expect(count, 0);
      expect(painted(t), baseline);
      await t.tapAt(baseline.center);
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(count, 0);
      expect(t.binding.transientCallbackCount, 0);
    });
  }
  for (var mode = 1; mode <= 4; mode++) {
    testWidgets(
      'reduced motion $mode switches during press and restores idle',
      (t) async {
        var reduced = 0;
        late StateSetter update;
        await t.pumpWidget(
          StatefulBuilder(
            builder: (c, set) {
              update = set;
              return app(subject('button', () {}), reduced: reduced);
            },
          ),
        );
        final baseline = painted(t);
        final g = await t.startGesture(baseline.center);
        await t.pump(const Duration(milliseconds: 20));
        update(() => reduced = mode);
        await t.pump();
        expect(painted(t), baseline);
        await g.up();
        await t.pumpAndSettle();
        update(() => reduced = 0);
        await t.pumpAndSettle();
        expect(painted(t), baseline);
        expect(t.binding.transientCallbackCount, 0);
      },
    );
  }
}
