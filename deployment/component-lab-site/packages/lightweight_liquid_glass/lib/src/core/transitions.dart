import 'package:flutter/material.dart';
import 'motion_spec.dart';

Widget buildGlassTransition(
  Animation<double> animation,
  Widget child,
  GlassMotionSpec spec, {
  bool reduceMotion = false,
}) {
  if (reduceMotion || spec.transition == GlassTransition.none) return child;
  final progress = animation.drive(
    CurveTween(
      curve: animation.status == AnimationStatus.reverse
          ? spec.reverseCurve
          : spec.curve,
    ),
  );
  Widget result = child;
  switch (spec.transition) {
    case GlassTransition.fadeSlide:
      result = SlideTransition(
        position: Tween(
          begin: const Offset(0, .035),
          end: Offset.zero,
        ).animate(progress),
        child: result,
      );
    case GlassTransition.scaleFade:
      result = ScaleTransition(
        scale: Tween(begin: .97, end: 1.0).animate(progress),
        child: result,
      );
    case GlassTransition.sharedAxis:
      result = SlideTransition(
        position: Tween(
          begin: const Offset(.06, 0),
          end: Offset.zero,
        ).animate(progress),
        child: result,
      );
      result = ScaleTransition(
        scale: Tween(begin: .98, end: 1.0).animate(progress),
        child: result,
      );
    case GlassTransition.fade:
    case GlassTransition.none:
      break;
  }
  return FadeTransition(opacity: progress, child: result);
}
