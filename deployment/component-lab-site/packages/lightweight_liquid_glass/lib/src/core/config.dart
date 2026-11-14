import 'package:flutter/material.dart';

enum GlassQuality { low, balanced, high, adaptive }

/// Explicit limits, not a device benchmark. Adaptive uses conservative defaults.
@immutable
class GlassPerformanceConfig {
  const GlassPerformanceConfig({
    this.quality = GlassQuality.adaptive,
    this.blurEnabled = true,
    this.maxBlurSigma = 20,
    this.groupBackdropFilters = true,
    this.enableNoise = false,
    this.enableShadows = true,
    this.enableAnimations = true,
  }) : assert(maxBlurSigma >= 0 && maxBlurSigma < double.infinity);
  final GlassQuality quality;
  final bool blurEnabled;
  final double maxBlurSigma;
  final bool groupBackdropFilters;
  final bool enableNoise;
  final bool enableShadows;
  final bool enableAnimations;

  /// Copy selected fields while preserving all unspecified configuration.
  GlassPerformanceConfig copyWith({
    GlassQuality? quality,
    bool? blurEnabled,
    double? maxBlurSigma,
    bool? groupBackdropFilters,
    bool? enableNoise,
    bool? enableShadows,
    bool? enableAnimations,
  }) => GlassPerformanceConfig(
    quality: quality ?? this.quality,
    blurEnabled: blurEnabled ?? this.blurEnabled,
    maxBlurSigma: maxBlurSigma ?? this.maxBlurSigma,
    groupBackdropFilters: groupBackdropFilters ?? this.groupBackdropFilters,
    enableNoise: enableNoise ?? this.enableNoise,
    enableShadows: enableShadows ?? this.enableShadows,
    enableAnimations: enableAnimations ?? this.enableAnimations,
  );

  double get effectiveMaxBlurSigma => switch (quality) {
    GlassQuality.low => 0,
    GlassQuality.balanced || GlassQuality.adaptive => maxBlurSigma.clamp(0, 16),
    GlassQuality.high => maxBlurSigma,
  };
}

/// System high contrast and reduced motion always take precedence.
@immutable
class GlassAccessibilityConfig {
  const GlassAccessibilityConfig({
    this.highContrast = false,
    this.reduceMotion = false,
    this.reduceTransparency = false,
  });

  /// Copy selected fields while preserving all unspecified configuration.
  GlassAccessibilityConfig copyWith({
    bool? highContrast,
    bool? reduceMotion,
    bool? reduceTransparency,
  }) => GlassAccessibilityConfig(
    highContrast: highContrast ?? this.highContrast,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    reduceTransparency: reduceTransparency ?? this.reduceTransparency,
  );

  final bool highContrast;
  final bool reduceMotion;
  final bool reduceTransparency;
}
