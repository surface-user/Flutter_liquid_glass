import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

void main() {
  testWidgets(
    'original public entry constructs a themed consumer without src imports',
    (tester) async {
      const style = GlassStyle();
      const motion = GlassMotionSpec();
      const config = GlassPerformanceConfig(quality: GlassQuality.high);
      const accessibility = GlassAccessibilityConfig();
      const theme = LiquidGlassThemeData(
        defaultStyle: style,
        motion: motion,
        performance: config,
        accessibility: accessibility,
      );
      final focus = FocusNode();
      addTearDown(focus.dispose);
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [theme]),
          home: LiquidGlassTheme(
            data: theme.copyWith(cardStyle: GlassPresets.subtle),
            child: Scaffold(
              appBar: const GlassAppBar(title: Text('Public consumer')),
              body: GlassBackdrop(
                child: GlassGroup(
                  child: GlassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AnimatedGlassSurface(
                          style: style,
                          child: const Text('surface'),
                        ),
                        GlassButton(
                          focusNode: focus,
                          onPressed: () => taps++,
                          child: const Text('action'),
                        ),
                        GlassIconButton(
                          icon: const Icon(Icons.add),
                          tooltip: 'Add',
                          onPressed: () {},
                        ),
                        Builder(
                          builder: (context) => GlassButton(
                            onPressed: () => showGlassDialog<void>(
                              context: context,
                              motion: const GlassMotionSpec(
                                transition: GlassTransition.none,
                              ),
                              builder: (context) => const GlassDialog(
                                content: Text('public dialog'),
                              ),
                            ),
                            child: const Text('dialog'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('action'));
      await tester.pumpAndSettle();
      expect(taps, 1);
      await tester.tap(find.text('dialog'));
      await tester.pumpAndSettle();
      expect(find.text('public dialog'), findsOneWidget);
      final route = GlassPageRoute<void>(
        builder: (context) => const GlassSurface(child: Text('page')),
      );
      expect(route.spec.duration, motion.duration);
      expect(LiquidGlassThemeData.dark().brightness, Brightness.dark);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
