import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

Widget _scene(
  Widget child, {
  LiquidGlassThemeData theme = const LiquidGlassThemeData(),
  MediaQueryData media = const MediaQueryData(),
  bool tickers = true,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(platform: TargetPlatform.windows, extensions: [theme]),
  home: MediaQuery(
    data: media,
    child: Scaffold(
      body: Center(
        child: TickerMode(enabled: tickers, child: child),
      ),
    ),
  ),
);

List<CustomPainter> _foregroundPainters(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .where((paint) => paint.child is Material || paint.child is InkWell)
    .map((paint) => paint.foregroundPainter)
    .whereType<CustomPainter>()
    .toList();

void main() {
  test('legacy component getters preserve omitted and explicit values', () {
    expect(
      const GlassButton(onPressed: null, child: SizedBox()).padding,
      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    );
    expect(
      const GlassCard(child: SizedBox()).padding,
      const EdgeInsets.all(20),
    );
    const surface = AnimatedGlassSurface(
      style: GlassStyle(),
      child: SizedBox(),
    );
    expect(surface.duration, const Duration(milliseconds: 240));
    expect(surface.curve, Curves.easeOutCubic);
    const inherited = AnimatedGlassSurface(
      style: GlassStyle(),
      duration: null,
      curve: null,
      child: SizedBox(),
    );
    expect(inherited.duration, surface.duration);
    expect(inherited.curve, surface.curve);
    const custom = AnimatedGlassSurface(
      style: GlassStyle(),
      child: SizedBox(),
      duration: Duration(milliseconds: 17),
      curve: Curves.linear,
    );
    expect(custom.duration, const Duration(milliseconds: 17));
    expect(custom.curve, Curves.linear);
  });

  testWidgets('transition uses separate forward and reverse curves', (
    tester,
  ) async {
    const childKey = ValueKey('motion-child');
    late GlassPageRoute<void> route;
    late BuildContext source;
    await tester.pumpWidget(
      _scene(
        Builder(
          builder: (context) {
            source = context;
            return const Text('Origin');
          },
        ),
      ),
    );
    route = GlassPageRoute<void>(
      motion: const GlassMotionSpec(
        transition: GlassTransition.sharedAxis,
        duration: Duration(seconds: 1),
        reverseDuration: Duration(seconds: 1),
        curve: Curves.linear,
        reverseCurve: Curves.easeInCubic,
      ),
      builder: (_) => const Scaffold(body: SizedBox(key: childKey)),
    );
    unawaited(Navigator.of(source).push(route));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    FadeTransition fade() => tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.byKey(childKey),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    // Native pump uses a real clock; compare the curve at measured progress.
    expect(route.animation!.value, inExclusiveRange(.25, .75));
    expect(fade().opacity.value, closeTo(route.animation!.value, .001));
    await tester.pumpAndSettle();
    Navigator.of(source).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(route.animation!.value, inExclusiveRange(.25, .75));
    expect(
      fade().opacity.value,
      closeTo(Curves.easeInCubic.transform(route.animation!.value), .001),
    );
    await tester.pumpAndSettle();
    expect(find.text('Origin'), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('disabled surface preserves clipping, layout and child actions', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _scene(
        GlassSurface(
          enabled: false,
          width: 180,
          height: 90,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.all(8),
          alignment: Alignment.bottomRight,
          child: TextButton(
            onPressed: () => taps++,
            child: const Text('Child'),
          ),
        ),
      ),
    );
    expect(find.byType(BackdropFilter), findsNothing);
    expect(_foregroundPainters(tester), isEmpty);
    expect(
      tester.widget<ClipRRect>(find.byType(ClipRRect)).clipBehavior,
      Clip.hardEdge,
    );
    expect(tester.getSize(find.byType(ClipRRect)), const Size(180, 90));
    await tester.tap(find.text('Child'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('circle rim and zero-sized effects paint without exceptions', (
    tester,
  ) async {
    for (final size in [0.0, 1.0, 60.0]) {
      await tester.pumpWidget(
        _scene(
          GlassSurface(
            width: size,
            height: size,
            clipBehavior: Clip.none,
            style: const GlassStyle(
              shape: BoxShape.circle,
              borderWidth: 40,
              noiseEnabled: true,
              noiseOpacity: .1,
              borderGradient: LinearGradient(colors: [Colors.red, Colors.blue]),
            ),
            child: const SizedBox.shrink(),
          ),
          theme: const LiquidGlassThemeData(
            performance: GlassPerformanceConfig(enableNoise: true),
          ),
        ),
      );
      expect(
        tester.widget<ClipOval>(find.byType(ClipOval)).clipBehavior,
        Clip.hardEdge,
      );
      final painter = _foregroundPainters(tester).single;
      final recorder = ui.PictureRecorder();
      painter.paint(Canvas(recorder), Size(size, size));
      recorder.endRecording().dispose();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'grouping compares effective filters and follows policy updates',
    (tester) async {
      Widget pair(GlassStyle second, {bool enabled = true}) => _scene(
        GlassGroup(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GlassSurface(child: SizedBox(width: 40, height: 40)),
              GlassSurface(
                style: second,
                child: const SizedBox(width: 40, height: 40),
              ),
            ],
          ),
        ),
        theme: LiquidGlassThemeData(
          defaultStyle: const GlassStyle(blurSigmaX: 40, blurSigmaY: 40),
          performance: GlassPerformanceConfig(groupBackdropFilters: enabled),
        ),
      );
      List<RenderBackdropFilter> filters() => tester
          .renderObjectList<RenderBackdropFilter>(find.byType(BackdropFilter))
          .toList();
      await tester.pumpWidget(
        pair(const GlassStyle(blurSigmaX: 30, blurSigmaY: 30)),
      );
      expect(filters().first.backdropKey, isNotNull);
      expect(filters().last.backdropKey, same(filters().first.backdropKey));
      for (final second in [
        const GlassStyle(blurSigmaX: 30, blurSigmaY: 30, saturation: .8),
        const GlassStyle(blurSigmaX: 30, blurSigmaY: 30, contrast: 1.1),
      ]) {
        await tester.pumpWidget(pair(second));
        expect(filters().last.backdropKey, isNull);
      }
      await tester.pumpWidget(
        pair(const GlassStyle(blurSigmaX: 30, blurSigmaY: 30), enabled: false),
      );
      await tester.pumpAndSettle();
      expect(filters().every((filter) => filter.backdropKey == null), isTrue);

      var nestedBuilds = 0;
      final nested = GlassSurface(
        child: Builder(
          builder: (_) {
            nestedBuilds++;
            return const SizedBox(width: 40, height: 40);
          },
        ),
      );
      Widget nestedScene(Color tint) => _scene(
        GlassGroup(
          child: GlassSurface(
            style: GlassPresets.card.copyWith(tintColor: tint),
            child: nested,
          ),
        ),
      );
      await tester.pumpWidget(nestedScene(Colors.red));
      await tester.pumpAndSettle();
      final before = nestedBuilds;
      await tester.pumpWidget(nestedScene(Colors.blue));
      expect(nestedBuilds, before);
      expect(filters().first.backdropKey, isNotNull);
      expect(filters().last.backdropKey, isNull);
    },
  );

  testWidgets(
    'animated surface keeps both target sigmas and blur enable discrete',
    (tester) async {
      const child = SizedBox(width: 80, height: 60);
      Widget scene(GlassStyle style) => _scene(
        AnimatedGlassSurface(
          style: style,
          duration: const Duration(seconds: 1),
          curve: Curves.linear,
          child: child,
        ),
      );
      await tester.pumpWidget(
        scene(const GlassStyle(blurSigmaX: 2, blurSigmaY: 3)),
      );
      await tester.pumpWidget(
        scene(
          const GlassStyle(
            blurSigmaX: 8,
            blurSigmaY: 14,
            blurEnabled: false,
            tintOpacity: .8,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
      var surface = tester.widget<GlassSurface>(find.byType(GlassSurface));
      expect(surface.style!.blurSigmaX, 8);
      expect(surface.style!.blurSigmaY, 14);
      expect(surface.style!.blurEnabled, isFalse);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(surface.child, same(child));
      await tester.pumpWidget(
        scene(const GlassStyle(blurSigmaX: 5, blurSigmaY: 9, tintOpacity: .2)),
      );
      await tester.pump(const Duration(milliseconds: 250));
      surface = tester.widget<GlassSurface>(find.byType(GlassSurface));
      expect(surface.style!.blurSigmaX, 5);
      expect(surface.style!.blurSigmaY, 9);
      expect(surface.style!.blurEnabled, isTrue);
      expect(find.byType(BackdropFilter), findsOneWidget);
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets(
    'backdrop updates repaint colors and intensity without an idle ticker',
    (tester) async {
      final colors = [Colors.red, Colors.blue];
      Widget scene({double intensity = 1}) => _scene(
        SizedBox(
          width: 200,
          height: 120,
          child: GlassBackdrop(colors: colors, intensity: intensity),
        ),
      );
      CustomPainter painter() => tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((widget) => widget.painter)
          .whereType<CustomPainter>()
          .single;
      await tester.pumpWidget(scene());
      var previous = painter();
      await tester.pumpWidget(scene());
      expect(painter().shouldRepaint(previous), isFalse);
      previous = painter();
      colors[0] = Colors.green;
      await tester.pumpWidget(scene());
      expect(painter().shouldRepaint(previous), isTrue);
      previous = painter();
      await tester.pumpWidget(scene(intensity: .2));
      expect(painter().shouldRepaint(previous), isTrue);
      final recorder = ui.PictureRecorder();
      painter().paint(Canvas(recorder), Size.zero);
      recorder.endRecording().dispose();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets(
    'backdrop animation starts, stops, resets and disposes dynamically',
    (tester) async {
      Widget scene({
        bool animate = true,
        bool tickers = true,
        MediaQueryData media = const MediaQueryData(),
        LiquidGlassThemeData theme = const LiquidGlassThemeData(),
      }) => _scene(
        SizedBox(
          width: 200,
          height: 120,
          child: GlassBackdrop(animate: animate),
        ),
        tickers: tickers,
        media: media,
        theme: theme,
      );
      Transform transform() => tester.widget<Transform>(
        find.descendant(
          of: find.byType(GlassBackdrop),
          matching: find.byType(Transform),
        ),
      );
      await tester.pumpWidget(scene());
      await tester.pump(const Duration(seconds: 1));
      expect(transform().transform.isIdentity(), isFalse);
      expect(tester.hasRunningAnimations, isTrue);
      for (final stopped in [
        scene(animate: false),
        scene(tickers: false),
        scene(media: const MediaQueryData(disableAnimations: true)),
        scene(media: const MediaQueryData(accessibleNavigation: true)),
        scene(
          theme: const LiquidGlassThemeData(
            accessibility: GlassAccessibilityConfig(reduceMotion: true),
          ),
        ),
        scene(
          theme: const LiquidGlassThemeData(
            performance: GlassPerformanceConfig(enableAnimations: false),
          ),
        ),
      ]) {
        await tester.pumpWidget(stopped);
        await tester.pumpAndSettle();
        expect(transform().transform.isIdentity(), isTrue);
        expect(tester.hasRunningAnimations, isFalse);
        expect(tester.binding.transientCallbackCount, 0);
        await tester.pumpWidget(scene());
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.hasRunningAnimations, isTrue);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets(
    'foreground painters only invalidate changed styles or pointer identity',
    (tester) async {
      Widget scene({GlassStyle? style, bool enabled = true}) => _scene(
        GlassButton(
          style: style,
          onPressed: enabled ? () {} : null,
          child: const SizedBox(width: 80, height: 30),
        ),
      );
      await tester.pumpWidget(scene());
      var old = _foregroundPainters(tester);
      expect(old.length, 2);
      await tester.pumpWidget(scene());
      var current = _foregroundPainters(tester);
      for (var i = 0; i < current.length; i++) {
        expect(current[i].shouldRepaint(old[i]), isFalse);
      }
      old = current;
      await tester.pumpWidget(
        scene(style: const GlassStyle(shape: BoxShape.circle)),
      );
      current = _foregroundPainters(tester);
      for (var i = 0; i < current.length; i++) {
        expect(current[i].shouldRepaint(old[i]), isTrue);
      }
      final mouse = await tester.createGesture(
        kind: ui.PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: const Offset(5, 5));
      await mouse.moveTo(tester.getCenter(find.byType(GlassButton)));
      await tester.pumpAndSettle();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      for (final paint in _foregroundPainters(tester)) {
        paint.paint(canvas, const Size(80, 80));
        paint.paint(canvas, Size.zero);
      }
      recorder.endRecording().dispose();
      await tester.pumpWidget(scene(enabled: false));
      await tester.pumpAndSettle();
      await mouse.removePointer();
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
      expect(tester.binding.transientCallbackCount, 0);
    },
  );
}
