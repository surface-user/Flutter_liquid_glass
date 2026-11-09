import 'package:flutter_test/flutter_test.dart';
import '../integration_test/frame_metrics.dart';

void main() {
  test('empty idle is no frames, not a fictional zero percentile', () {
    final result = summarizeFrames([], [], 60);
    expect(result['build'], {
      'count': 0,
      'p50_ms': null,
      'p95_ms': null,
      'max_ms': null,
      'over_budget': 0,
    });
    expect(result['frames_over_budget'], 0);
  });
  test('nearest rank percentiles and paired frame budget count', () {
    final build = [20.0, 1.0, 10.0];
    final result = summarizeFrames(build, [21, 30, 2], 100);
    expect(result['build'], {
      'count': 3,
      'p50_ms': 10.0,
      'p95_ms': 20.0,
      'max_ms': 20.0,
      'over_budget': 1,
    });
    expect(result['frames_over_budget'], 2);
    expect(build, [20.0, 1.0, 10.0]);
    final twenty = frameMetrics(List.generate(20, (i) => i + 1.0), 10);
    expect(twenty['p50_ms'], 10);
    expect(twenty['p95_ms'], 19);
    expect(twenty['over_budget'], 10);
  });
  test('invalid timings, pairs and refresh rates are rejected', () {
    expect(() => summarizeFrames([1], [], 60), throwsArgumentError);
    for (final rate in [0.0, -60.0, double.nan, double.infinity]) {
      expect(() => summarizeFrames([], [], rate), throwsArgumentError);
    }
    for (final value in [-1.0, double.nan, double.infinity]) {
      expect(() => frameMetrics([value], 16), throwsArgumentError);
    }
  });
}
