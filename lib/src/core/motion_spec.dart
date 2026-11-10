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
  });
  final GlassTransition transition;
  final Duration duration, reverseDuration;
  final Curve curve, reverseCurve;
}
