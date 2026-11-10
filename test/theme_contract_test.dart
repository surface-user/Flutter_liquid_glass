import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

Widget host(
  Widget child, [
  LiquidGlassThemeData theme = const LiquidGlassThemeData(),
]) => MaterialApp(
  theme: ThemeData(extensions: [theme]),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('transparent control overlay preserves the base material tint', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        GlassButton(
          onPressed: () {},
          style: const GlassStyle(tintColor: Colors.red, tintOpacity: .2),
          controlStyle: const ButtonStyle(
            overlayColor: WidgetStatePropertyAll(Colors.transparent),
          ),
          child: const Text('Tint'),
        ),
      ),
    );
    final style = tester.widget<GlassSurface>(find.byType(GlassSurface)).style!;
    expect(
      style.tintColor.withValues(alpha: 1).toARGB32(),
      Colors.red.toARGB32(),
    );
    expect(style.tintColor.a * style.tintOpacity, closeTo(.2, .000001));
  });
  testWidgets(
    'explicit material keeps its base tint and border over inherited control decoration',
    (tester) async {
      const theme = LiquidGlassThemeData(
        controlStyle: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(Colors.blue),
          side: WidgetStatePropertyAll(BorderSide(color: Colors.green)),
        ),
      );
      await tester.pumpWidget(
        host(
          GlassButton(
            onPressed: () {},
            style: const GlassStyle(
              tintColor: Colors.red,
              borderColor: Colors.orange,
              borderWidth: 3,
            ),
            child: const Text('Explicit material'),
          ),
          theme,
        ),
      );
      final surface = tester.widget<GlassSurface>(find.byType(GlassSurface));
      expect(surface.style!.tintColor, Colors.red);
      expect(surface.style!.borderColor, Colors.orange);
      expect(surface.style!.borderWidth, 3);
    },
  );
  testWidgets('null state override inherits the corresponding theme state', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        GlassButton(
          controlStyle: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) =>
                  states.contains(WidgetState.pressed) ? Colors.red : null,
            ),
          ),
          onPressed: () {},
          child: const Text('Inherited state'),
        ),
        const LiquidGlassThemeData(
          controlStyle: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(Colors.blue),
          ),
        ),
      ),
    );
    Color? color() => DefaultTextStyle.of(
      tester.element(find.text('Inherited state')),
    ).style.color;
    expect(color(), Colors.blue);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(GlassButton)),
    );
    await tester.pumpAndSettle();
    expect(color(), Colors.red);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(color(), Colors.blue);
  });
  test(
    'nested configuration copies preserve parent restrictions and durations',
    () {
      const performance = GlassPerformanceConfig(
        maxBlurSigma: 7,
        enableAnimations: false,
      );
      final local = performance.copyWith(blurEnabled: false);
      expect(local.maxBlurSigma, 7);
      expect(local.enableAnimations, isFalse);
      expect(local.blurEnabled, isFalse);
      expect(performance.blurEnabled, isTrue);
      expect(
        const GlassAccessibilityConfig(
          highContrast: true,
        ).copyWith(reduceMotion: true).highContrast,
        isTrue,
      );
      final motion = const GlassMotionSpec().copyWith(
        pressDuration: Duration.zero,
      );
      expect(motion.pressDuration, Duration.zero);
      expect(motion.duration, const Duration(milliseconds: 280));
    },
  );
  test(
    'copyWith retains, explicitly clears and resets nullable configuration',
    () {
      const colors = ColorScheme.dark();
      const source = LiquidGlassThemeData(
        colorScheme: colors,
        layout: GlassLayout(iconSize: 18, appBarTitleSpacing: 9),
      );
      expect(source.copyWith().colorScheme, same(colors));
      expect(source.copyWith(colorScheme: null).colorScheme, isNull);
      expect(source.layout.copyWith().iconSize, 18);
      expect(source.layout.copyWith(iconSize: null).iconSize, isNull);
      expect(
        source.layout.copyWith(appBarTitleSpacing: null).appBarTitleSpacing,
        isNull,
      );
      expect(source.layout.iconSize, 18);
      expect(
        GlassLayout.lerp(
          const GlassLayout(iconSize: null),
          source.layout,
          .25,
        ).iconSize,
        isNull,
      );
      expect(
        GlassLayout.lerp(
          const GlassLayout(iconSize: null),
          source.layout,
          .75,
        ).iconSize,
        18,
      );
      expect(
        GlassLayout.lerp(
          const GlassLayout(dialogMaxWidth: 400),
          const GlassLayout(dialogMaxWidth: 600),
          .5,
        ).dialogMaxWidth,
        500,
      );
      expect(() => GlassLayout(dialogMaxWidth: -1), throwsAssertionError);
    },
  );

  test(
    'theme interpolation keeps target sigma and the stricter policies until completion',
    () {
      const source = LiquidGlassThemeData(
        defaultStyle: GlassStyle(blurSigmaX: 2),
      );
      const target = LiquidGlassThemeData(
        defaultStyle: GlassStyle(blurSigmaX: 18),
        performance: GlassPerformanceConfig(
          blurEnabled: false,
          enableAnimations: false,
        ),
        accessibility: GlassAccessibilityConfig(
          highContrast: true,
          reduceMotion: true,
        ),
      );
      for (final t in [.01, .25, .75, .99]) {
        final value = source.lerp(target, t);
        expect(value.defaultStyle.blurSigmaX, 18);
        expect(value.performance.blurEnabled, isFalse);
        expect(value.performance.enableAnimations, isFalse);
        expect(value.accessibility.highContrast, isTrue);
        expect(value.accessibility.reduceMotion, isTrue);
        expect(target.lerp(source, t).performance.blurEnabled, isFalse);
        expect(target.lerp(source, t).accessibility.reduceMotion, isTrue);
      }
      expect(source.lerp(target, 0), same(source));
      expect(source.lerp(target, 1), same(target));
    },
  );

  testWidgets(
    'nested merge preserves parent fields, clears gradients and isolates siblings',
    (tester) async {
      const gradient = LinearGradient(colors: [Colors.red, Colors.blue]);
      const global = LiquidGlassThemeData(
        accentColor: Colors.purple,
        cardStyle: GlassStyle(backgroundGradient: gradient),
        layout: GlassLayout(dialogMaxWidth: 600),
      );
      final seen = <String, LiquidGlassThemeData>{};
      Widget record(String key) => Builder(
        builder: (context) {
          seen[key] = LiquidGlassTheme.of(context);
          return const SizedBox.shrink();
        },
      );
      await tester.pumpWidget(
        host(
          Column(
            children: [
              LiquidGlassTheme.merge(
                data: (parent) => parent.copyWith(
                  cardStyle: parent.cardStyle.copyWith(
                    backgroundGradient: null,
                  ),
                  layout: parent.layout.copyWith(iconSize: 18),
                ),
                child: LiquidGlassTheme.merge(
                  data: (parent) => parent.copyWith(accentColor: Colors.green),
                  child: record('nested'),
                ),
              ),
              LiquidGlassTheme.merge(
                data: (parent) =>
                    parent.copyWith(visualDensity: VisualDensity.compact),
                child: record('sibling'),
              ),
              LiquidGlassTheme(
                data: const LiquidGlassThemeData(),
                child: record('legacy'),
              ),
            ],
          ),
          global,
        ),
      );
      expect(seen['nested']!.cardStyle.backgroundGradient, isNull);
      expect(seen['nested']!.layout.dialogMaxWidth, 600);
      expect(seen['nested']!.layout.iconSize, 18);
      expect(seen['nested']!.accentColor, Colors.green);
      expect(seen['sibling']!.cardStyle.backgroundGradient, same(gradient));
      expect(seen['sibling']!.accentColor, Colors.purple);
      expect(seen['sibling']!.layout.iconSize, isNull);
      expect(seen['legacy']!.layout.dialogMaxWidth, 480);
    },
  );

  testWidgets('explicit padding wins and compact targets remain deliberate', (
    tester,
  ) async {
    const theme = LiquidGlassThemeData(
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      layout: GlassLayout(buttonPadding: EdgeInsets.all(10)),
    );
    Widget button({EdgeInsetsGeometry? padding}) => GlassButton(
      onPressed: () {},
      padding: padding,
      child: const SizedBox(width: 10, height: 10),
    );
    await tester.pumpWidget(host(button(), theme));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(GlassButton)), const Size(40, 40));
    await tester.pumpWidget(
      host(
        button(),
        theme.copyWith(tapTargetSize: MaterialTapTargetSize.padded),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(GlassButton)), const Size(48, 48));
    await tester.pumpWidget(
      host(button(padding: const EdgeInsets.all(30)), theme),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(GlassButton)), const Size(70, 70));
    expect(
      const GlassButton(onPressed: null, child: SizedBox()).padding,
      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    );
    expect(
      const GlassCard(child: SizedBox()).padding,
      const EdgeInsets.all(20),
    );
  });

  testWidgets(
    'state colors and text/icon tokens resolve with explicit control precedence',
    (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      final themed = ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? Colors.grey
              : states.contains(WidgetState.focused)
              ? Colors.green
              : states.contains(WidgetState.hovered)
              ? Colors.orange
              : Colors.blue,
        ),
      );
      final theme = LiquidGlassThemeData(
        controlStyle: themed,
        layout: const GlassLayout(iconSize: 18),
        textTheme: const TextTheme(labelLarge: TextStyle(fontSize: 19)),
      );
      Widget scene({bool disabled = false, ButtonStyle? override}) => host(
        GlassButton(
          focusNode: focus,
          onPressed: disabled ? null : () {},
          controlStyle: override,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(Icons.add), Text('Action')],
          ),
        ),
        theme,
      );
      Color? textColor() =>
          DefaultTextStyle.of(tester.element(find.text('Action'))).style.color;
      await tester.pumpWidget(scene());
      expect(textColor(), Colors.blue);
      expect(
        DefaultTextStyle.of(tester.element(find.text('Action'))).style.fontSize,
        19,
      );
      expect(IconTheme.of(tester.element(find.byType(Icon))).size, 18);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byType(GlassButton)));
      await tester.pumpAndSettle();
      expect(textColor(), Colors.orange);
      focus.requestFocus();
      await tester.pumpAndSettle();
      expect(textColor(), Colors.green);
      await tester.pumpWidget(
        scene(
          override: const ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(Colors.purple),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(textColor(), Colors.purple);
      await tester.pumpWidget(scene(disabled: true));
      await tester.pumpAndSettle();
      expect(textColor(), Colors.grey);
      await mouse.removePointer();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('dynamic merged themes keep focus and release cleanup', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    final theme = ValueNotifier(const LiquidGlassThemeData());
    addTearDown(theme.dispose);
    var taps = 0;
    await tester.pumpWidget(
      host(
        ValueListenableBuilder(
          valueListenable: theme,
          builder: (context, value, child) => LiquidGlassTheme.merge(
            data: (parent) => value.copyWith(accentColor: parent.accentColor),
            child: GlassButton(
              focusNode: focus,
              onPressed: () => taps++,
              child: const Text('Stable'),
            ),
          ),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(GlassButton)),
    );
    await tester.pump(const Duration(milliseconds: 20));
    theme.value = LiquidGlassThemeData.dark().copyWith(
      accessibility: const GlassAccessibilityConfig(reduceMotion: true),
    );
    await tester.pump();
    await gesture.up();
    theme.value = const LiquidGlassThemeData();
    await tester.pumpAndSettle();
    expect(focus.hasFocus, isTrue);
    expect(taps, 1);
    expect(tester.binding.transientCallbackCount, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(taps, 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('high contrast overrides decorative foreground and fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassButton(onPressed: () {}, child: const Text('Readable')),
            const GlassSurface(
              fallbackColor: Colors.black,
              child: Text('Fallback'),
            ),
          ],
        ),
        const LiquidGlassThemeData(
          colorScheme: ColorScheme.light(
            onSurface: Colors.white,
            surface: Colors.black,
          ),
          controlStyle: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(Colors.white),
          ),
          accessibility: GlassAccessibilityConfig(highContrast: true),
        ),
      ),
    );
    expect(find.byType(BackdropFilter), findsNothing);
    expect(
      DefaultTextStyle.of(tester.element(find.text('Readable'))).style.color,
      const Color(0xff17233b),
    );
    final colors = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((box) => box.decoration)
        .whereType<BoxDecoration>()
        .map((decoration) => decoration.color);
    expect(colors.where((color) => color == Colors.black), isEmpty);
  });

  testWidgets('theme lerp never continuously changes the actual blur filter', (
    tester,
  ) async {
    const a = LiquidGlassThemeData(
      defaultStyle: GlassStyle(blurSigmaX: 2, blurSigmaY: 2),
    );
    const b = LiquidGlassThemeData(
      defaultStyle: GlassStyle(blurSigmaX: 14, blurSigmaY: 14),
    );
    for (final t in [.1, .3, .7]) {
      await tester.pumpWidget(
        host(
          const GlassSurface(child: SizedBox(width: 80, height: 50)),
          a.lerp(b, t),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<BackdropFilter>(find.byType(BackdropFilter)).filter,
        ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      );
    }
  });

  testWidgets('compact Chinese and English text grows at 2x without clipping', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      host(
        GlassButton(
          onPressed: () {},
          child: const Text('学习资料 Learning materials long label'),
        ),
        const LiquidGlassThemeData(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(GlassButton)).height, greaterThan(40));
    expect(tester.takeException(), isNull);
  });
}
