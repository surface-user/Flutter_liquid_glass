import 'package:flutter/material.dart';

enum GlassTransition { fade, fadeSlide, scaleFade, sharedAxis, none }

@immutable
class GlassMotionSpec {
  const GlassMotionSpec({
    this.transition = GlassTransition.fadeSlide,
    this.duration = const Duration(milliseconds: 280),
    this.reverseDuration = const Duration(milliseconds: 220),
    this.curve = Curves.easeOutCubic,
    this.reverseCurve = Curves.easeInCubic,
    this.pressDuration = const Duration(milliseconds: 90),
    this.hoverDuration = const Duration(milliseconds: 160),
    this.releaseDuration = const Duration(milliseconds: 180),
    this.surfaceDuration = const Duration(milliseconds: 240),
    this.interactionCurve = Curves.easeOutCubic,
  });

  /// Copy selected fields while preserving all unspecified configuration.
  GlassMotionSpec copyWith({
    GlassTransition? transition,
    Duration? duration,
    Duration? reverseDuration,
    Curve? curve,
    Curve? reverseCurve,
    Duration? pressDuration,
    Duration? hoverDuration,
    Duration? releaseDuration,
    Duration? surfaceDuration,
    Curve? interactionCurve,
  }) => GlassMotionSpec(
    transition: transition ?? this.transition,
    duration: duration ?? this.duration,
    reverseDuration: reverseDuration ?? this.reverseDuration,
    curve: curve ?? this.curve,
    reverseCurve: reverseCurve ?? this.reverseCurve,
    pressDuration: pressDuration ?? this.pressDuration,
    hoverDuration: hoverDuration ?? this.hoverDuration,
    releaseDuration: releaseDuration ?? this.releaseDuration,
    surfaceDuration: surfaceDuration ?? this.surfaceDuration,
    interactionCurve: interactionCurve ?? this.interactionCurve,
  );

  final GlassTransition transition;
  final Duration duration, reverseDuration;
  final Curve curve, reverseCurve;

  /// State feedback and surface durations; reduced motion overrides all of them.
  final Duration pressDuration, hoverDuration, releaseDuration, surfaceDuration;
  final Curve interactionCurve;
}
