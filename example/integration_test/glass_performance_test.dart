import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';
import 'frame_sampler.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets('Android glass idle and interaction profile', (tester) async {
    expect(
      Platform.isAndroid && kProfileMode,
      isTrue,
      reason: 'Run on an Android device with flutter drive --profile.',
    );
    binding.reportData = {
      'platform': Platform.operatingSystem,
      'os_version': Platform.operatingSystemVersion,
      'fixture':
          'Three isolated interactive glass components on a static backdrop',
      'percentile_method': 'nearest_rank',
      'modes': <String, Object?>{},
    };
    for (final mode in [
      'default',
      'no_blur',
      'high_contrast',
      'reduce_motion',
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [
              LiquidGlassThemeData(
                performance: GlassPerformanceConfig(
                  blurEnabled: mode != 'no_blur',
                ),
                accessibility: GlassAccessibilityConfig(
                  highContrast: mode == 'high_contrast',
                  reduceMotion: mode == 'reduce_motion',
                ),
              ),
            ],
          ),
          home: Scaffold(
            body: GlassBackdrop(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GlassButton(
                      key: const ValueKey('button'),
                      onPressed: () {},
                      child: const Text('Press'),
                    ),
                    const SizedBox(height: 24),
                    GlassIconButton(
                      key: const ValueKey('icon'),
                      onPressed: () {},
                      tooltip: 'Icon',
                      icon: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 24),
                    GlassCard(
                      key: const ValueKey('card'),
                      onTap: () {},
                      child: const Text('Card'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Let engine timing batches and initial shader work drain before sampling.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 2)),
      );
      final idle = await sample(tester, () async {
        // No pump: observing idle must not manufacture frames.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 10)),
        );
      });
      final interaction = await sample(tester, () async {
        final watch = Stopwatch()..start();
        while (watch.elapsed < const Duration(seconds: 30)) {
          for (final key in ['button', 'icon', 'card']) {
            final gesture = await tester.startGesture(
              tester.getCenter(find.byKey(ValueKey(key))),
            );
            await tester.pump(const Duration(milliseconds: 110));
            await tester.pump(const Duration(milliseconds: 110));
            await gesture.up();
            await tester.pump(const Duration(milliseconds: 220));
          }
        }
        await tester.pumpAndSettle();
      });
      (binding.reportData!['modes'] as Map<String, Object?>)[mode] = {
        'idle': idle,
        'interaction': interaction,
      };
      expect(
        (interaction['build'] as Map)['count'],
        greaterThan(0),
        reason: 'No frame samples: this run is not valid performance evidence.',
      );
      expect(
        binding.transientCallbackCount,
        0,
        reason: 'Interaction ticker did not stop.',
      );
    }
  }, timeout: const Timeout(Duration(minutes: 8)));
}
