import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

Widget host(
  Widget child, {
  LiquidGlassThemeData theme = const LiquidGlassThemeData(),
  MediaQueryData media = const MediaQueryData(),
}) => MaterialApp(
  theme: ThemeData(extensions: [theme]),
  home: MediaQuery(
    data: media,
    child: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  testWidgets(
    'source context resolves theme motion and removes system animation duration',
    (tester) async {
      late GlassPageRoute<void> route;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) {
              route = GlassPageRoute<void>(
                context: context,
                builder: (_) => const SizedBox(),
              );
              return const SizedBox();
            },
          ),
          media: const MediaQueryData(disableAnimations: true),
          theme: const LiquidGlassThemeData(
            motion: GlassMotionSpec(transition: GlassTransition.scaleFade),
          ),
        ),
      );
      expect(route.spec.transition, GlassTransition.scaleFade);
      expect(route.transitionDuration, Duration.zero);
      expect(route.reverseTransitionDuration, Duration.zero);
      route.dispose();
    },
  );
  testWidgets('different filter settings never share group input', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        GlassGroup(
          child: const Column(
            children: [
              GlassSurface(child: SizedBox(width: 40, height: 40)),
              GlassSurface(
                style: GlassStyle(blurSigmaX: 6),
                child: SizedBox(width: 40, height: 40),
              ),
            ],
          ),
        ),
      ),
    );
    final filters = tester
        .renderObjectList<RenderBackdropFilter>(find.byType(BackdropFilter))
        .toList();
    expect(filters.first.backdropKey, isNotNull);
    expect(filters.last.backdropKey, isNull);
  });
  testWidgets('reduce transparency ignores decorative gradients', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const GlassSurface(
          fallbackColor: Color(0x33887766),
          style: GlassStyle(
            backgroundGradient: LinearGradient(
              colors: [Colors.red, Colors.blue],
            ),
          ),
          child: SizedBox(width: 60, height: 60),
        ),
        theme: const LiquidGlassThemeData(
          accessibility: GlassAccessibilityConfig(reduceTransparency: true),
        ),
      ),
    );
    expect(find.byType(BackdropFilter), findsNothing);
    final decorations = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((widget) => widget.decoration)
        .whereType<BoxDecoration>();
    expect(
      decorations.any(
        (decoration) =>
            decoration.color == const Color(0xff887766) &&
            decoration.gradient == null,
      ),
      isTrue,
    );
  });
  testWidgets('surface bounds and clips filtering while preserving child', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const GlassSurface(
          width: 180,
          height: 90,
          padding: EdgeInsets.all(12),
          clipBehavior: Clip.none,
          child: Text('Crisp'),
        ),
      ),
    );
    expect(find.text('Crisp'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(
      tester.widget<ClipRRect>(find.byType(ClipRRect)).clipBehavior,
      Clip.hardEdge,
    );
    expect(tester.getSize(find.byType(BackdropFilter)), const Size(180, 90));
    expect(
      find.ancestor(
        of: find.text('Crisp'),
        matching: find.byType(ColorFiltered),
      ),
      findsNothing,
    );
  });
  testWidgets('all fallback switches remove backdrop filters', (tester) async {
    for (final config in [
      const GlassPerformanceConfig(blurEnabled: false),
      const GlassPerformanceConfig(quality: GlassQuality.low),
      const GlassPerformanceConfig(maxBlurSigma: 0),
    ]) {
      await tester.pumpWidget(
        host(
          const GlassSurface(child: Text('fallback')),
          theme: LiquidGlassThemeData(performance: config),
        ),
      );
      expect(find.byType(BackdropFilter), findsNothing);
    }
    await tester.pumpWidget(
      host(
        const GlassSurface(child: Text('contrast')),
        media: const MediaQueryData(highContrast: true),
      ),
    );
    expect(find.byType(BackdropFilter), findsNothing);
    await tester.pumpWidget(
      host(const GlassSurface(enabled: false, child: Text('disabled'))),
    );
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.text('disabled'), findsOneWidget);
  });
  testWidgets(
    'group shares non-overlapping filters, overlap and nested are isolated',
    (tester) async {
      Widget pair(bool overlap) => GlassGroup(
        overlapping: overlap,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassSurface(child: SizedBox(width: 60, height: 40)),
            GlassSurface(child: SizedBox(width: 60, height: 40)),
          ],
        ),
      );
      await tester.pumpWidget(host(pair(false)));
      var filters = tester
          .renderObjectList<RenderBackdropFilter>(find.byType(BackdropFilter))
          .toList();
      expect(filters[0].backdropKey, isNotNull);
      expect(filters[0].backdropKey, same(filters[1].backdropKey));
      await tester.pumpWidget(host(pair(true)));
      filters = tester
          .renderObjectList<RenderBackdropFilter>(find.byType(BackdropFilter))
          .toList();
      expect(filters.every((filter) => filter.backdropKey == null), isTrue);
      await tester.pumpWidget(
        host(
          GlassGroup(
            child: const GlassSurface(
              child: GlassSurface(child: SizedBox(width: 80, height: 60)),
            ),
          ),
        ),
      );
      filters = tester
          .renderObjectList<RenderBackdropFilter>(find.byType(BackdropFilter))
          .toList();
      expect(filters[0].backdropKey, isNotNull);
      expect(filters[1].backdropKey, isNull);
    },
  );
  testWidgets('button responds to pointer and keyboard; disabled does not', (
    tester,
  ) async {
    var count = 0;
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      host(
        GlassButton(
          focusNode: focus,
          onPressed: () => count++,
          child: const Text('Go'),
        ),
      ),
    );
    await tester.tap(find.text('Go'));
    expect(count, 1);
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(count, 2);
    expect(
      tester.getSize(find.byType(GlassSurface)).height,
      greaterThanOrEqualTo(48),
    );
    await tester.pumpWidget(
      host(const GlassButton(onPressed: null, child: Text('Off'))),
    );
    await tester.tap(find.text('Off'));
    expect(count, 2);
  });
  testWidgets('animated style interpolates tint but holds target blur', (
    tester,
  ) async {
    Widget scene(GlassStyle style, {bool reduced = false}) => host(
      AnimatedGlassSurface(
        duration: const Duration(seconds: 1),
        curve: Curves.linear,
        style: style,
        child: const SizedBox(width: 80, height: 60),
      ),
      media: MediaQueryData(disableAnimations: reduced),
    );
    const start = GlassStyle(tintOpacity: .1, blurSigmaX: 4);
    const end = GlassStyle(tintOpacity: .9, blurSigmaX: 16);
    await tester.pumpWidget(scene(start));
    await tester.pumpWidget(scene(end));
    await tester.pump(const Duration(milliseconds: 500));
    var style = tester.widget<GlassSurface>(find.byType(GlassSurface)).style!;
    expect(style.tintOpacity, closeTo(.5, .01));
    expect(style.blurSigmaX, 16);
    await tester.pumpWidget(scene(start, reduced: true));
    await tester.pump();
    style = tester.widget<GlassSurface>(find.byType(GlassSurface)).style!;
    expect(style.tintOpacity, .1);
  });
  testWidgets('dialog captures local theme and returns result', (tester) async {
    String? result;
    final dark = LiquidGlassThemeData.dark();
    await tester.pumpWidget(
      host(
        LiquidGlassTheme(
          data: dark,
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showGlassDialog<String>(
                  context: context,
                  builder: (context) => GlassDialog(
                    title: const Text('Dialog'),
                    content: const Text('Readable'),
                    actions: [
                      GlassButton(
                        onPressed: () => Navigator.pop(context, 'ok'),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(
      LiquidGlassTheme.of(tester.element(find.byType(GlassDialog))).brightness,
      Brightness.dark,
    );
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(result, 'ok');
  });
  testWidgets('reduced motion suppresses backdrop ticker', (tester) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 300,
          height: 300,
          child: GlassBackdrop(animate: true),
        ),
        media: const MediaQueryData(disableAnimations: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });
  for (final transition in GlassTransition.values) {
    testWidgets('route ${transition.name} pushes and pops', (tester) async {
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                GlassPageRoute<void>(
                  motion: GlassMotionSpec(transition: transition),
                  builder: (context) => Scaffold(
                    body: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Return'),
                    ),
                  ),
                ),
              ),
              child: const Text('Push'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Push'));
      await tester.pumpAndSettle();
      expect(find.text('Return'), findsOneWidget);
      await tester.tap(find.text('Return'));
      await tester.pumpAndSettle();
      expect(find.text('Push'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
