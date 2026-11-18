import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

void main() {
  for (final openDialog in [false, true]) {
    testWidgets(
      'reversing a partially opened glass ${openDialog ? 'dialog' : 'page'} preserves its appearance',
      (tester) async {
        const marker = ValueKey('glass-route-content');
        final triggerFocus = FocusNode();
        addTearDown(triggerFocus.dispose);
        Widget buildContent(BuildContext context) =>
            const Center(child: SizedBox(key: marker, width: 160, height: 80));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  autofocus: true,
                  focusNode: triggerFocus,
                  onPressed: () {
                    if (openDialog) {
                      showGlassDialog<void>(
                        context: context,
                        builder: buildContent,
                      );
                    } else {
                      Navigator.of(context).push(
                        GlassPageRoute<void>(
                          context: context,
                          builder: buildContent,
                        ),
                      );
                    }
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(triggerFocus.hasPrimaryFocus, isTrue);
        await tester.tap(find.text('Open'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 140));

        final content = find.byKey(marker);
        final initialContent = tester.element(content);
        final route = ModalRoute.of<void>(initialContent)!;
        final fade = find
            .ancestor(of: content, matching: find.byType(FadeTransition))
            .first;
        double opacity() => tester.widget<FadeTransition>(fade).opacity.value;
        double barrierOpacity() => tester
            .widget<AnimatedModalBarrier>(find.byType(AnimatedModalBarrier))
            .color
            .value!
            .a;
        final initialOpacity = opacity();
        final initialY = tester.getTopLeft(content).dy;
        final initialBarrierOpacity = openDialog ? barrierOpacity() : null;
        expect(route.animation!.value, closeTo(.5, .001));

        route.navigator!.pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));

        expect(route.animation!.status, AnimationStatus.reverse);
        final reversedY = tester.getTopLeft(content).dy;
        expect(
          opacity(),
          closeTo(initialOpacity, .02),
          reason:
              'Content moved from y=$initialY to y=$reversedY while reversing.',
        );
        expect(reversedY, closeTo(initialY, .25));
        expect(tester.element(content), same(initialContent));
        if (initialBarrierOpacity != null) {
          expect(barrierOpacity(), closeTo(initialBarrierOpacity, .01));
        }
        await tester.pumpAndSettle();
        expect(content, findsNothing);
        expect(triggerFocus.hasPrimaryFocus, isTrue);

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        final completedRoute = ModalRoute.of<void>(tester.element(content))!;
        expect(completedRoute.animation!.status, AnimationStatus.completed);
        completedRoute.navigator!.pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 110));
        expect(completedRoute.animation!.value, closeTo(.5, .001));
        expect(opacity(), closeTo(Curves.easeInCubic.transform(.5), .001));
        await tester.pumpAndSettle();
        expect(content, findsNothing);
      },
    );
  }
}
