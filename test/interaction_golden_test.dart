import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';
import 'widget_test.dart' show host;

void main() {
  for (final state in ['pressed', 'hovered', 'focused', 'reduced', 'pointer']) {
    testWidgets('interaction visual / $state', (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        host(
          RepaintBoundary(
            key: const ValueKey('interaction'),
            child: SizedBox(
              width: 240,
              height: 100,
              child: Center(
                child: GlassButton(
                  focusNode: focus,
                  onPressed: () {},
                  child: const FlutterLogo(size: 24),
                ),
              ),
            ),
          ),
          media: MediaQueryData(disableAnimations: state == 'reduced'),
        ),
      );
      final ink = tester.widget<InkWell>(find.byType(InkWell));
      if (state == 'focused') focus.requestFocus();
      if (state == 'hovered') ink.onHover!(true);
      final gesture = state == 'pressed' || state == 'reduced'
          ? await tester.startGesture(
              tester.getCenter(find.byType(GlassButton)),
            )
          : null;
      final mouse = state == 'pointer'
          ? await tester.createGesture(kind: PointerDeviceKind.mouse)
          : null;
      if (mouse != null) {
        await mouse.addPointer(location: const Offset(5, 5));
        final rect = tester.getRect(find.byType(GlassButton));
        await mouse.moveTo(rect.topLeft + const Offset(10, 8));
      }
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const ValueKey('interaction')),
        matchesGoldenFile('goldens/interaction-$state.png'),
      );
      await mouse?.removePointer();
      await gesture?.cancel();
      await tester.pumpAndSettle();
    });
  }
}
