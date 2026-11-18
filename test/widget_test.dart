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
    const retarget = GlassStyle(tintOpacity: .7, blurSigmaX: 8);
    await tester.pumpWidget(scene(start));
    await tester.pumpWidget(scene(end));
    await tester.pump(const Duration(milliseconds: 500));
    var style = tester.widget<GlassSurface>(find.byType(GlassSurface)).style!;
    expect(style.tintOpacity, closeTo(.5, .01));
    expect(style.blurSigmaX, 16);
    await tester.pumpWidget(scene(retarget));
    style = tester.widget<GlassSurface>(find.byType(GlassSurface)).style!;
    expect(style.tintOpacity, closeTo(.5, .01));
    expect(style.blurSigmaX, 8);
    await tester.pump(const Duration(milliseconds: 500));
    style = tester.widget<GlassSurface>(find.byType(GlassSurface)).style!;
    expect(style.tintOpacity, closeTo(.6, .01));
    await tester.pumpWidget(scene(start, reduced: true));
    await tester.pump();
    style = tester.widget<GlassSurface>(find.byType(GlassSurface)).style!;
    expect(style.tintOpacity, .1);
  });
  const reductionCases = [
    (
      'disableAnimations',
      MediaQueryData(disableAnimations: true),
      LiquidGlassThemeData(),
    ),
    (
      'accessibleNavigation',
      MediaQueryData(accessibleNavigation: true),
      LiquidGlassThemeData(),
    ),
    (
      'reduceMotion',
      MediaQueryData(),
      LiquidGlassThemeData(
        accessibility: GlassAccessibilityConfig(reduceMotion: true),
      ),
    ),
    (
      'enableAnimations=false',
      MediaQueryData(),
      LiquidGlassThemeData(
        performance: GlassPerformanceConfig(enableAnimations: false),
      ),
    ),
  ];
  for (final (reason, media, theme) in reductionCases) {
    testWidgets(
      'reducing motion finishes the current surface transition ($reason)',
      (tester) async {
        const start = GlassStyle(tintOpacity: .1, blurSigmaX: 4, blurSigmaY: 5);
        const target = GlassStyle(
          tintOpacity: .9,
          blurSigmaX: 16,
          blurSigmaY: 12,
        );
        Widget scene(GlassStyle style, {bool reduced = false}) => host(
          LiquidGlassTheme(
            data: reduced ? theme : const LiquidGlassThemeData(),
            child: AnimatedGlassSurface(
              style: style,
              duration: const Duration(seconds: 1),
              curve: Curves.linear,
              child: const SizedBox(
                width: 240,
                child: TextField(showCursor: false),
              ),
            ),
          ),
          media: reduced ? media : const MediaQueryData(),
        );
        GlassStyle paintedStyle() =>
            tester.widget<GlassSurface>(find.byType(GlassSurface)).style!;

        await tester.pumpWidget(scene(start));
        final field = find.byType(EditableText);
        await tester.enterText(field, 'draft');
        await tester.pumpAndSettle();
        final editor = tester.state<EditableTextState>(field);
        expect(editor.widget.focusNode.hasFocus, isTrue);

        await tester.pumpWidget(scene(target));
        expect(paintedStyle().blurSigmaX, target.blurSigmaX);
        expect(paintedStyle().blurSigmaY, target.blurSigmaY);
        await tester.pump(const Duration(milliseconds: 500));
        expect(paintedStyle().tintOpacity, closeTo(.5, .01));
        expect(paintedStyle().blurSigmaX, target.blurSigmaX);
        expect(paintedStyle().blurSigmaY, target.blurSigmaY);

        await tester.pumpWidget(scene(target, reduced: true));
        expect(paintedStyle().tintOpacity, target.tintOpacity);
        expect(tester.hasRunningAnimations, isFalse);
        expect(tester.state<EditableTextState>(field), same(editor));
        expect(editor.widget.focusNode.hasFocus, isTrue);
        expect(editor.widget.controller.text, 'draft');

        await tester.pumpWidget(scene(target));
        expect(paintedStyle().tintOpacity, target.tintOpacity);
        expect(tester.hasRunningAnimations, isFalse);
      },
    );
  }
  testWidgets(
    'independent platform reduce motion finishes the surface transition',
    (tester) async {
      final dispatcher = tester.platformDispatcher;
      dispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);

      const start = GlassStyle(tintOpacity: .1);
      const target = GlassStyle(tintOpacity: .9);
      Widget scene(GlassStyle style) => host(
        AnimatedGlassSurface(
          style: style,
          duration: const Duration(seconds: 1),
          curve: Curves.linear,
          child: const SizedBox(
            width: 240,
            child: TextField(showCursor: false),
          ),
        ),
      );
      GlassStyle paintedStyle() =>
          tester.widget<GlassSurface>(find.byType(GlassSurface)).style!;

      await tester.pumpWidget(scene(start));
      final field = find.byType(EditableText);
      await tester.enterText(field, 'draft');
      await tester.pumpAndSettle();
      final editor = tester.state<EditableTextState>(field);
      final fieldRect = tester.getRect(field);

      await tester.pumpWidget(scene(target));
      await tester.pump(const Duration(milliseconds: 500));
      expect(paintedStyle().tintOpacity, closeTo(.5, .01));

      dispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(reduceMotion: true);
      await tester.pump();
      expect(paintedStyle().tintOpacity, target.tintOpacity);
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.state<EditableTextState>(field), same(editor));
      expect(editor.widget.focusNode.hasFocus, isTrue);
      expect(editor.widget.controller.text, 'draft');
      expect(tester.getRect(field), fieldRect);

      dispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      await tester.pump();
      expect(paintedStyle().tintOpacity, target.tintOpacity);
      expect(tester.hasRunningAnimations, isFalse);

      await tester.pumpWidget(scene(start));
      await tester.pump(const Duration(milliseconds: 500));
      expect(paintedStyle().tintOpacity, closeTo(.5, .01));
      await tester.pumpWidget(const SizedBox());
      dispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(reduceMotion: true);
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('platform reduce motion pauses the optional backdrop loop', (
    tester,
  ) async {
    final dispatcher = tester.platformDispatcher;
    void reduceMotion(bool value) {
      dispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(
        reduceMotion: value,
      );
    }

    reduceMotion(false);
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);

    Widget scene({
      bool visible = true,
      bool animate = true,
      bool reducedByTheme = false,
    }) => host(
      LiquidGlassTheme(
        data: LiquidGlassThemeData(
          accessibility: GlassAccessibilityConfig(reduceMotion: reducedByTheme),
        ),
        child: TickerMode(
          enabled: visible,
          child: SizedBox(
            width: 320,
            height: 200,
            child: GlassBackdrop(
              animate: animate,
              child: const Center(child: Text('Backdrop content')),
            ),
          ),
        ),
      ),
    );
    final transform = find.descendant(
      of: find.byType(GlassBackdrop),
      matching: find.byType(Transform),
    );
    double verticalOffset() =>
        tester.widget<Transform>(transform).transform.getTranslation().y;

    await tester.pumpWidget(scene());
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(verticalOffset(), greaterThan(0));
    final content = tester.getRect(find.text('Backdrop content'));

    reduceMotion(true);
    await tester.pump();
    expect(verticalOffset(), 0);
    expect(tester.getRect(find.text('Backdrop content')), content);
    expect(tester.hasRunningAnimations, isFalse);

    reduceMotion(false);
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(verticalOffset(), greaterThan(0));

    reduceMotion(true);
    await tester.pumpWidget(scene(reducedByTheme: true));
    reduceMotion(false);
    await tester.pump();
    expect(verticalOffset(), 0);
    expect(tester.hasRunningAnimations, isFalse);

    await tester.pumpWidget(scene(visible: false));
    reduceMotion(true);
    await tester.pump();
    reduceMotion(false);
    await tester.pump();
    expect(verticalOffset(), 0);
    expect(tester.hasRunningAnimations, isFalse);

    await tester.pumpWidget(scene(animate: false));
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pumpWidget(scene());
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpWidget(const SizedBox());
    reduceMotion(true);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });
  testWidgets('a new glass page route reads platform reduce motion', (
    tester,
  ) async {
    final dispatcher = tester.platformDispatcher;
    dispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      reduceMotion: true,
    );
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
    late GlassPageRoute<void> route;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () {
              route = GlassPageRoute<void>(
                context: context,
                builder: (_) => const Center(child: Text('Destination')),
              );
              Navigator.of(context).push(route);
            },
            child: const Text('Push'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Push'));
    await tester.pump();
    expect(route.transitionDuration, Duration.zero);
    expect(route.reverseTransitionDuration, Duration.zero);
    expect(route.animation!.status, AnimationStatus.completed);
    expect(find.text('Destination'), findsOneWidget);
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
  testWidgets('dialog uses distinct entrance and exit durations', (
    tester,
  ) async {
    String? result;
    late ModalRoute<String> route;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showGlassDialog<String>(
                context: context,
                motion: const GlassMotionSpec(
                  transition: GlassTransition.fade,
                  duration: Duration(milliseconds: 400),
                  reverseDuration: Duration(milliseconds: 120),
                ),
                builder: (context) {
                  route = ModalRoute.of<String>(context)!;
                  return const Text('Timed dialog');
                },
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(route.animation!.value, closeTo(.5, .001));
    await tester.pump(const Duration(milliseconds: 201));
    expect(route.animation!.status, AnimationStatus.completed);

    route.navigator!.pop('done');
    await tester.pump();
    expect(result, 'done');
    await tester.pump(const Duration(milliseconds: 60));
    expect(route.animation!.value, closeTo(.5, .001));
    expect(find.text('Timed dialog'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 61));
    await tester.pump();
    expect(find.text('Timed dialog'), findsNothing);
  });
  for (final useRootNavigator in [true, false]) {
    testWidgets(
      'dialog respects navigator and barrier (root=$useRootNavigator)',
      (tester) async {
        final root = GlobalKey<NavigatorState>();
        final inner = GlobalKey<NavigatorState>();
        final localTheme = ThemeData.dark();
        const settings = RouteSettings(name: '/confirmation');
        late String? result;
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: root,
            home: Navigator(
              key: inner,
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  body: Center(
                    child: Theme(
                      data: localTheme,
                      child: Builder(
                        builder: (context) => TextButton(
                          onPressed: () async {
                            result = await showGlassDialog<String>(
                              context: context,
                              useRootNavigator: useRootNavigator,
                              barrierDismissible: !useRootNavigator,
                              routeSettings: settings,
                              builder: (_) =>
                                  const Dialog(child: Text('Nested dialog')),
                            );
                          },
                          child: const Text('Open'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        final dialog = find.text('Nested dialog');
        final context = tester.element(dialog);
        final route = ModalRoute.of<String>(context)!;
        expect(route.navigator, (useRootNavigator ? root : inner).currentState);
        expect(route.settings, same(settings));
        expect(route.barrierDismissible, !useRootNavigator);
        expect(
          route.barrierLabel,
          MaterialLocalizations.of(context).modalBarrierDismissLabel,
        );
        expect(route.barrierColor, Colors.black.withValues(alpha: .32));
        expect(Theme.of(context).colorScheme, localTheme.colorScheme);
        expect(route.transitionDuration, const Duration(milliseconds: 280));
        expect(
          route.reverseTransitionDuration,
          const Duration(milliseconds: 220),
        );

        await tester.tapAt(const Offset(8, 8));
        await tester.pumpAndSettle();
        if (useRootNavigator) {
          expect(dialog, findsOneWidget);
          Navigator.of(context).pop('done');
          await tester.pumpAndSettle();
        }
        expect(dialog, findsNothing);
        expect(result, useRootNavigator ? 'done' : null);
      },
    );
  }
  const stillMotionCases = [
    (
      'disableAnimations',
      MediaQueryData(disableAnimations: true),
      LiquidGlassThemeData(),
    ),
    (
      'accessibleNavigation',
      MediaQueryData(accessibleNavigation: true),
      LiquidGlassThemeData(),
    ),
    (
      'reduceMotion',
      MediaQueryData(),
      LiquidGlassThemeData(
        accessibility: GlassAccessibilityConfig(reduceMotion: true),
      ),
    ),
    (
      'enableAnimations=false',
      MediaQueryData(),
      LiquidGlassThemeData(
        performance: GlassPerformanceConfig(enableAnimations: false),
      ),
    ),
    (
      'GlassTransition.none',
      MediaQueryData(),
      LiquidGlassThemeData(
        motion: GlassMotionSpec(transition: GlassTransition.none),
      ),
    ),
  ];
  for (final (reason, media, theme) in stillMotionCases) {
    testWidgets('dialog skips both transitions for $reason', (tester) async {
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showGlassDialog<void>(
                context: context,
                builder: (_) => const Text('Still dialog'),
              ),
              child: const Text('Open'),
            ),
          ),
          media: media,
          theme: theme,
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      final dialog = find.text('Still dialog');
      final context = tester.element(dialog);
      final route = ModalRoute.of<void>(context)!;
      expect(route.transitionDuration, Duration.zero);
      expect(route.reverseTransitionDuration, Duration.zero);
      expect(route.animation!.status, AnimationStatus.completed);
      Navigator.of(context).pop();
      await tester.pump();
      await tester.pump();
      expect(dialog, findsNothing);
    });
  }
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
