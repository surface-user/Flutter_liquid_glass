import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

Widget _host(Widget child, {LiquidGlassThemeData? glass}) => MaterialApp(
  theme: ThemeData(
    platform: TargetPlatform.windows,
    extensions: [if (glass != null) glass],
  ),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  test('audit core: style equality distinguishes every appearance field', () {
    const source = GlassStyle();
    const gradient = LinearGradient(colors: [Colors.red, Colors.blue]);
    final variants = [
      source.copyWith(blurSigmaX: 1),
      source.copyWith(blurSigmaY: 1),
      source.copyWith(blurEnabled: false),
      source.copyWith(tintColor: Colors.red),
      source.copyWith(tintOpacity: .3),
      source.copyWith(backgroundGradient: gradient),
      source.copyWith(saturation: 2),
      source.copyWith(contrast: 2),
      source.copyWith(borderColor: Colors.red),
      source.copyWith(borderOpacity: .3),
      source.copyWith(borderWidth: 2),
      source.copyWith(borderGradient: gradient),
      source.copyWith(borderRadius: BorderRadius.zero),
      source.copyWith(shape: BoxShape.circle),
      source.copyWith(highlightColor: Colors.red),
      source.copyWith(highlightOpacity: .3),
      source.copyWith(highlightAngle: 2),
      source.copyWith(shadowColor: Colors.red),
      source.copyWith(shadowOpacity: .3),
      source.copyWith(shadowBlurRadius: 2),
      source.copyWith(shadowOffset: Offset.zero),
      source.copyWith(noiseOpacity: .3),
      source.copyWith(noiseEnabled: true),
    ];
    expect(source == Object(), isFalse);
    expect(source.copyWith(), source);
    expect(source.copyWith().hashCode, source.hashCode);
    expect({source, source.copyWith(), ...variants}, hasLength(24));
    for (final variant in variants) {
      expect(variant, isNot(source));
      expect(variant.copyWith(), variant);
      expect(variant.copyWith().hashCode, variant.hashCode);
    }
  });

  test(
    'audit core: style interpolation covers discrete and gradient fields',
    () {
      const a = GlassStyle(blurEnabled: false, shape: BoxShape.circle);
      const b = GlassStyle(
        blurSigmaY: 20,
        backgroundGradient: LinearGradient(colors: [Colors.red, Colors.blue]),
        borderGradient: LinearGradient(colors: [Colors.green, Colors.orange]),
        saturation: 2,
        contrast: 2,
        highlightOpacity: .5,
        highlightAngle: .8,
        shadowOpacity: .5,
        shadowBlurRadius: 40,
        shadowOffset: Offset(10, 20),
        noiseOpacity: .5,
        noiseEnabled: true,
      );
      expect(GlassStyle.lerp(a, b, -1), same(a));
      expect(GlassStyle.lerp(a, b, 2), same(b));
      expect(GlassStyle.lerp(a, b, .49).blurEnabled, isFalse);
      expect(GlassStyle.lerp(a, b, .49).shape, BoxShape.circle);
      expect(GlassStyle.lerp(a, b, .49).noiseEnabled, isFalse);
      final mid = GlassStyle.lerp(a, b, .5);
      expect(mid.blurSigmaY, 16);
      expect(mid.blurEnabled, isTrue);
      expect(mid.shape, BoxShape.rectangle);
      expect(mid.noiseEnabled, isTrue);
      expect(mid.backgroundGradient, isNotNull);
      expect(mid.borderGradient, isNotNull);
      expect(mid.saturation, 1.5);
      expect(mid.contrast, 1.5);
      expect(mid.highlightOpacity, closeTo(.34, 1e-9));
      expect(mid.highlightAngle, 0);
      expect(mid.shadowOpacity, closeTo(.3, 1e-9));
      expect(mid.shadowBlurRadius, 30);
      expect(mid.shadowOffset, const Offset(5, 14));
      expect(mid.noiseOpacity, closeTo(.2625, 1e-9));
    },
  );

  test('audit core: invalid numeric styles and quality limits are bounded', () {
    for (final invalid in [-1.0, double.nan, double.infinity]) {
      for (final create in <GlassStyle Function()>[
        () => GlassStyle(blurSigmaX: invalid),
        () => GlassStyle(blurSigmaY: invalid),
        () => GlassStyle(tintOpacity: invalid),
        () => GlassStyle(borderOpacity: invalid),
        () => GlassStyle(highlightOpacity: invalid),
        () => GlassStyle(shadowOpacity: invalid),
        () => GlassStyle(noiseOpacity: invalid),
        () => GlassStyle(borderWidth: invalid),
        () => GlassStyle(shadowBlurRadius: invalid),
        () => GlassStyle(saturation: invalid),
        () => GlassStyle(contrast: invalid),
      ]) {
        expect(create, throwsAssertionError);
      }
      expect(
        () => GlassPerformanceConfig(maxBlurSigma: invalid),
        throwsAssertionError,
      );
    }
    for (final quality in GlassQuality.values) {
      for (final budget in [0.0, 5.0, 30.0]) {
        final config = GlassPerformanceConfig(
          quality: quality,
          maxBlurSigma: budget,
        );
        expect(config.effectiveMaxBlurSigma, lessThanOrEqualTo(budget));
        if (quality == GlassQuality.low) {
          expect(config.effectiveMaxBlurSigma, 0);
        } else if (quality == GlassQuality.high) {
          expect(config.effectiveMaxBlurSigma, budget);
        } else {
          expect(config.effectiveMaxBlurSigma, lessThanOrEqualTo(16));
        }
      }
    }
  });

  test('audit core: nested config copies support false and zero overrides', () {
    const source = GlassPerformanceConfig(
      quality: GlassQuality.high,
      maxBlurSigma: 8,
      enableNoise: true,
    );
    final copy = source.copyWith(
      quality: GlassQuality.low,
      blurEnabled: false,
      maxBlurSigma: 0,
      groupBackdropFilters: false,
      enableNoise: false,
      enableShadows: false,
      enableAnimations: false,
    );
    expect(copy.quality, GlassQuality.low);
    expect(copy.maxBlurSigma, 0);
    expect([
      copy.blurEnabled,
      copy.groupBackdropFilters,
      copy.enableNoise,
      copy.enableShadows,
      copy.enableAnimations,
    ], everyElement(isFalse));
    expect(source.enableNoise, isTrue);
    const access = GlassAccessibilityConfig(
      highContrast: true,
      reduceMotion: true,
      reduceTransparency: true,
    );
    final allowed = access.copyWith(
      highContrast: false,
      reduceMotion: false,
      reduceTransparency: false,
    );
    expect([
      allowed.highContrast,
      allowed.reduceMotion,
      allowed.reduceTransparency,
    ], everyElement(isFalse));
    final motion = const GlassMotionSpec().copyWith(
      transition: GlassTransition.none,
      duration: Duration.zero,
      reverseDuration: Duration.zero,
      curve: Curves.linear,
      reverseCurve: Curves.linear,
      pressDuration: Duration.zero,
      hoverDuration: Duration.zero,
      releaseDuration: Duration.zero,
      surfaceDuration: Duration.zero,
      interactionCurve: Curves.linear,
    );
    expect(motion.transition, GlassTransition.none);
    expect([
      motion.duration,
      motion.reverseDuration,
      motion.pressDuration,
      motion.hoverDuration,
      motion.releaseDuration,
      motion.surfaceDuration,
    ], everyElement(Duration.zero));
    expect([
      motion.curve,
      motion.reverseCurve,
      motion.interactionCurve,
    ], everyElement(same(Curves.linear)));
  });

  test(
    'audit core: geometry copies and interpolation retain directional values',
    () {
      const source = GlassLayout(
        cardPadding: EdgeInsetsDirectional.only(start: 8),
        buttonPadding: EdgeInsets.all(2),
        iconButtonPadding: EdgeInsets.all(3),
        dialogPadding: EdgeInsets.all(4),
        dialogMaxWidth: 300,
        titleSpacing: 10,
        actionSpacing: 11,
        actionRunSpacing: 12,
        iconSize: 18,
        appBarTitleSpacing: 20,
      );
      final copy = source.copyWith(iconSize: 24, appBarTitleSpacing: 0);
      expect(copy.cardPadding, source.cardPadding);
      expect(copy.buttonPadding, source.buttonPadding);
      expect(copy.iconButtonPadding, source.iconButtonPadding);
      expect(copy.dialogPadding, source.dialogPadding);
      expect(copy.dialogMaxWidth, 300);
      expect(copy.titleSpacing, 10);
      expect(copy.actionSpacing, 11);
      expect(copy.actionRunSpacing, 12);
      expect(copy.iconSize, 24.0);
      expect(copy.appBarTitleSpacing, 0.0);
      final mid = GlassLayout.lerp(source, copy, .5);
      expect(mid.iconSize, 21);
      expect(mid.appBarTitleSpacing, 10);
      expect(mid.cardPadding.resolve(TextDirection.ltr).left, 8);
      expect(mid.cardPadding.resolve(TextDirection.rtl).right, 8);
      expect(copy.copyWith(iconSize: null).iconSize, isNull);
      expect(
        copy.copyWith(appBarTitleSpacing: null).appBarTitleSpacing,
        isNull,
      );
      for (final value in [-1.0, double.nan, double.infinity]) {
        expect(
          () => source.copyWith(dialogMaxWidth: value),
          throwsAssertionError,
        );
        expect(
          () => source.copyWith(titleSpacing: value),
          throwsAssertionError,
        );
        expect(
          () => source.copyWith(actionSpacing: value),
          throwsAssertionError,
        );
        expect(
          () => source.copyWith(actionRunSpacing: value),
          throwsAssertionError,
        );
        expect(() => source.copyWith(iconSize: value), throwsAssertionError);
        expect(
          () => source.copyWith(appBarTitleSpacing: value),
          throwsAssertionError,
        );
      }
      expect(() => source.copyWith(iconSize: 0), throwsAssertionError);
      expect(() => source.copyWith(dialogMaxWidth: 0), throwsAssertionError);
    },
  );

  test('audit theme: semantic colors, dark presets and nullable reset', () {
    const light = LiquidGlassThemeData();
    final dark = LiquidGlassThemeData.dark(accentColor: Colors.red);
    expect(light.foregroundColor, const Color(0xff17233b));
    expect(light.surfaceColor, const Color(0xffedf1f8));
    expect(light.focusColor, light.accentColor);
    expect(dark.foregroundColor, Colors.white);
    expect(dark.surfaceColor, const Color(0xff202a3c));
    expect(dark.focusColor, Colors.red);
    expect(dark.dialogStyle.tintOpacity, .94);
    for (final style in [
      dark.defaultStyle,
      dark.cardStyle,
      dark.buttonStyle,
      dark.appBarStyle,
    ]) {
      expect(style.tintColor, const Color(0xff182235));
      expect(style.tintOpacity, .65);
    }
    const scheme = ColorScheme.light(
      onSurface: Colors.purple,
      surface: Colors.orange,
      primary: Colors.green,
    );
    final semantic = light.copyWith(colorScheme: scheme);
    expect(semantic.foregroundColor, Colors.purple);
    expect(semantic.surfaceColor, Colors.orange);
    expect(semantic.focusColor, Colors.green);
    expect(semantic.copyWith().colorScheme, same(scheme));
    expect(
      semantic.copyWith(colorScheme: null).foregroundColor,
      light.foregroundColor,
    );
    expect(semantic.lerp(null, .5), same(semantic));
    expect(semantic.lerp(dark, -1), same(semantic));
    expect(semantic.lerp(dark, 2), same(dark));
  });

  test('audit theme: restrictive interpolation covers every material slot', () {
    const source = LiquidGlassThemeData(
      performance: GlassPerformanceConfig(
        quality: GlassQuality.low,
        groupBackdropFilters: false,
        enableShadows: false,
        enableAnimations: false,
      ),
      accessibility: GlassAccessibilityConfig(
        highContrast: true,
        reduceTransparency: true,
      ),
    );
    const target = LiquidGlassThemeData(
      defaultStyle: GlassStyle(blurSigmaX: 1, blurSigmaY: 2),
      cardStyle: GlassStyle(blurSigmaX: 3, blurSigmaY: 4),
      buttonStyle: GlassStyle(blurSigmaX: 5, blurSigmaY: 6),
      dialogStyle: GlassStyle(blurSigmaX: 7, blurSigmaY: 8),
      appBarStyle: GlassStyle(blurSigmaX: 9, blurSigmaY: 10),
      performance: GlassPerformanceConfig(enableNoise: true),
      accessibility: GlassAccessibilityConfig(reduceMotion: true),
    );
    for (final value in [.01, .5, .99]) {
      final mixed = source.lerp(target, value);
      final styles = [
        mixed.defaultStyle,
        mixed.cardStyle,
        mixed.buttonStyle,
        mixed.dialogStyle,
        mixed.appBarStyle,
      ];
      expect(styles.map((s) => s.blurSigmaX), [1, 3, 5, 7, 9]);
      expect(styles.map((s) => s.blurSigmaY), [2, 4, 6, 8, 10]);
      expect(mixed.performance.effectiveMaxBlurSigma, 0);
      expect(mixed.performance.groupBackdropFilters, isFalse);
      expect(mixed.performance.enableNoise, isFalse);
      expect(mixed.performance.enableShadows, isFalse);
      expect(mixed.performance.enableAnimations, isFalse);
      expect(mixed.accessibility.highContrast, isTrue);
      expect(mixed.accessibility.reduceTransparency, isTrue);
      expect(mixed.accessibility.reduceMotion, isTrue);
    }
  });

  testWidgets('audit theme: lookup fallback, update notification and wrap', (
    tester,
  ) async {
    late BuildContext sourceContext;
    late BuildContext targetContext;
    const custom = LiquidGlassThemeData(accentColor: Colors.red);
    const local = LiquidGlassTheme(data: custom, child: SizedBox());
    expect(local.updateShouldNotify(local), isFalse);
    expect(
      local.updateShouldNotify(
        const LiquidGlassTheme(data: LiquidGlassThemeData(), child: SizedBox()),
      ),
      isTrue,
    );
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) {
            sourceContext = context;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(LiquidGlassTheme.of(sourceContext).brightness, Brightness.light);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Builder(
          builder: (context) {
            sourceContext = context;
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(LiquidGlassTheme.of(sourceContext).brightness, Brightness.dark);
    await tester.pumpWidget(
      _host(
        local.wrap(
          sourceContext,
          Builder(
            builder: (context) {
              targetContext = context;
              return const SizedBox();
            },
          ),
        ),
        glass: const LiquidGlassThemeData(accentColor: Colors.blue),
      ),
    );
    expect(LiquidGlassTheme.of(targetContext), same(custom));
  });

  testWidgets('audit theme: directional compact padding resolves and clamps', (
    tester,
  ) async {
    for (final direction in TextDirection.values) {
      await tester.pumpWidget(
        _host(
          Directionality(
            textDirection: direction,
            child: const GlassCard(
              child: SizedBox(key: ValueKey('content'), width: 20, height: 20),
            ),
          ),
          glass: const LiquidGlassThemeData(
            visualDensity: VisualDensity.compact,
            layout: GlassLayout(
              cardPadding: EdgeInsetsDirectional.fromSTEB(2, 8, 12, 3),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final card = tester.getRect(find.byType(GlassCard));
      final content = tester.getRect(find.byKey(const ValueKey('content')));
      expect(
        EdgeInsets.fromLTRB(
          content.left - card.left,
          content.top - card.top,
          card.right - content.right,
          card.bottom - content.bottom,
        ),
        direction == TextDirection.ltr
            ? const EdgeInsets.fromLTRB(0, 4, 8, 0)
            : const EdgeInsets.fromLTRB(8, 4, 0, 0),
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('audit theme: high contrast card keeps inherited text readable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          platform: TargetPlatform.windows,
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
          ),
          extensions: const [
            LiquidGlassThemeData(
              accessibility: GlassAccessibilityConfig(highContrast: true),
            ),
          ],
        ),
        home: const Scaffold(
          body: GlassCard(child: Text('High contrast content')),
        ),
      ),
    );
    expect(find.byType(BackdropFilter), findsNothing);
    const background = Color(0xffedf1f8);
    expect(
      tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .map((decoration) => decoration.color),
      contains(background),
    );
    final foreground = DefaultTextStyle.of(
      tester.element(find.text('High contrast content')),
    ).style.color!;
    final foregroundLuminance = foreground.computeLuminance();
    final backgroundLuminance = background.computeLuminance();
    final contrast = foregroundLuminance > backgroundLuminance
        ? (foregroundLuminance + .05) / (backgroundLuminance + .05)
        : (backgroundLuminance + .05) / (foregroundLuminance + .05);
    expect(
      contrast,
      greaterThanOrEqualTo(4.5),
      reason:
          'Inherited Material body text must remain readable in high contrast.',
    );
  });
}
