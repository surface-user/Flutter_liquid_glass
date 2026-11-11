import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'frame_metrics.dart';

Future<Map<String, Object?>> sample(
  WidgetTester tester,
  Future<void> Function() action,
) async {
  final build = <double>[], raster = <double>[];
  void collect(List<FrameTiming> frames) {
    for (final frame in frames) {
      build.add(frame.buildDuration.inMicroseconds / 1000);
      raster.add(frame.rasterDuration.inMicroseconds / 1000);
    }
  }

  SchedulerBinding.instance.addTimingsCallback(collect);
  final watch = Stopwatch()..start();
  try {
    await action();
    watch.stop();
    // Timings are batched; allow the last engine report without scheduling a frame.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1100)),
    );
    return {
      'action_duration_ms': watch.elapsedMilliseconds,
      ...summarizeFrames(build, raster, tester.view.display.refreshRate),
    };
  } finally {
    SchedulerBinding.instance.removeTimingsCallback(collect);
  }
}
