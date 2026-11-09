import 'dart:math' as math;

Map<String, Object?> frameMetrics(List<double> values, double budgetMs) {
  if (!budgetMs.isFinite ||
      budgetMs <= 0 ||
      values.any((v) => !v.isFinite || v < 0)) {
    throw ArgumentError(
      'Frame times and frame budget must be finite and nonnegative.',
    );
  }
  final sorted = values.toList()..sort();
  return {
    'count': sorted.length,
    'p50_ms': sorted.isEmpty ? null : sorted[(sorted.length * .5).ceil() - 1],
    'p95_ms': sorted.isEmpty ? null : sorted[(sorted.length * .95).ceil() - 1],
    'max_ms': sorted.isEmpty ? null : sorted.last,
    'over_budget': sorted.where((v) => v > budgetMs).length,
  };
}

Map<String, Object?> summarizeFrames(
  List<double> buildMs,
  List<double> rasterMs,
  double refreshRate,
) {
  if (buildMs.length != rasterMs.length)
    throw ArgumentError('Unpaired frames.');
  final budget = 1000 / refreshRate;
  return {
    'refresh_rate_hz': refreshRate,
    'budget_ms': budget,
    'build': frameMetrics(buildMs, budget),
    'raster': frameMetrics(rasterMs, budget),
    'frames_over_budget': List.generate(
      buildMs.length,
      (i) => math.max(buildMs[i], rasterMs[i]),
    ).where((v) => v > budget).length,
    'raw_build_ms': buildMs,
    'raw_raster_ms': rasterMs,
  };
}
