import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'fixtures/desktop_consumer.dart';
import 'frame_sampler.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets('Windows desktop engine frame profile', (tester) async {
    expect(
      Platform.isWindows && kProfileMode,
      isTrue,
      reason:
          'Run on Windows with flutter drive --profile. Not Android evidence.',
    );
    binding.reportData = {
      'platform': Platform.operatingSystem,
      'os_version': Platform.operatingSystemVersion,
      'fixture':
          'Compact public desktop consumer, original glass button/card and SDK inputs/navigation/menu',
      'percentile_method': 'nearest_rank',
      'rendering_backend': 'not independently confirmed',
      'modes': <String, Object?>{},
    };
    for (final mode in [
      'default',
      'no_blur',
      'high_contrast',
      'reduce_motion',
    ]) {
      await tester.pumpWidget(
        DesktopConsumer(
          key: ValueKey(mode),
          noBlur: mode == 'no_blur',
          highContrast: mode == 'high_contrast',
          reduceMotion: mode == 'reduce_motion',
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 2)),
      );
      final idle = await sample(tester, () async {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 10)),
        );
      });
      final interaction = await sample(tester, () async {
        final watch = Stopwatch()..start();
        while (watch.elapsed < const Duration(seconds: 30)) {
          await tester.tap(find.byKey(const ValueKey('nav-b')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('desktop-dialog')));
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(
            LogicalKeyboardKey.escape,
            physicalKey: PhysicalKeyboardKey.escape,
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Actions'));
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(
            LogicalKeyboardKey.escape,
            physicalKey: PhysicalKeyboardKey.escape,
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('nav-a')));
          await tester.pumpAndSettle();
        }
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
      });
      (binding.reportData!['modes'] as Map<String, Object?>)[mode] = {
        'idle': idle,
        'interaction': interaction,
      };
      expect((interaction['build'] as Map)['count'], greaterThan(0));
      expect(
        binding.transientCallbackCount,
        0,
        reason: 'No idle interaction ticker after settling.',
      );
    }
  }, timeout: const Timeout(Duration(minutes: 8)));
}
