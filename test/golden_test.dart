import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

void main() {
  setUpAll(() async {
    final font = FontLoader('Roboto')
      ..addFont(
        File(
          'test/assets/Roboto-Regular.ttf',
        ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
      );
    await font.load();
  });
  for (final mode in ['light', 'dark', 'contrast', 'fallback']) {
    testWidgets('glass visual baseline / $mode', (tester) async {
      debugDisableShadows = false;
      addTearDown(() => debugDisableShadows = true);
      tester.view.physicalSize = const Size(720, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final theme =
          (mode == 'dark'
                  ? LiquidGlassThemeData.dark()
                  : const LiquidGlassThemeData())
              .copyWith(
                performance: GlassPerformanceConfig(
                  blurEnabled: mode != 'fallback',
                  enableNoise: true,
                ),
                accessibility: GlassAccessibilityConfig(
                  highContrast: mode == 'contrast',
                ),
              );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            fontFamily: 'Roboto',
            brightness: theme.brightness,
            extensions: [theme],
          ),
          home: RepaintBoundary(
            key: const ValueKey('scene'),
            child: Scaffold(
              body: GlassBackdrop(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      GlassGroup(
                        child: Row(
                          children: [
                            const Expanded(
                              child: GlassCard(
                                child: SizedBox(
                                  height: 120,
                                  child: Center(child: Text('Crisp content')),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            GlassSurface(
                              width: 160,
                              height: 160,
                              style: theme.defaultStyle.copyWith(
                                shape: BoxShape.circle,
                                noiseEnabled: true,
                                saturation: 1.3,
                                contrast: 1.1,
                              ),
                              child: const Center(
                                child: Text(
                                  'Glass',
                                  style: TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GlassButton(
                            onPressed: () {},
                            child: const Text('Continue'),
                          ),
                          const SizedBox(width: 16),
                          const GlassButton(
                            onPressed: null,
                            child: Text('Disabled'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      GlassSurface(
                        height: 64,
                        style: theme.defaultStyle.copyWith(
                          borderRadius: BorderRadius.zero,
                        ),
                        child: const Center(
                          child: Text('Straight edges / bounded blur'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const ValueKey('scene')),
        matchesGoldenFile('goldens/$mode.png'),
      );
      expect(tester.takeException(), isNull);
      debugDisableShadows = true;
    });
  }
}
