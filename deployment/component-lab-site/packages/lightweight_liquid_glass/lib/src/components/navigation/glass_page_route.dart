import 'package:flutter/material.dart';
import '../../core/motion_spec.dart';
import '../../core/transitions.dart';
import '../../theme/theme.dart';

/// Animates composition, never the backdrop blur radius.
class GlassPageRoute<T> extends PageRouteBuilder<T> {
  factory GlassPageRoute({
    required WidgetBuilder builder,
    BuildContext? context,
    GlassMotionSpec? motion,
    bool reduceMotion = false,
    RouteSettings? settings,
    bool fullscreenDialog = false,
  }) {
    final spec =
        motion ??
        (context == null
            ? const GlassMotionSpec()
            : LiquidGlassTheme.of(context).motion);
    final reduced =
        reduceMotion || (context != null && glassReduceMotion(context));
    final themes = context == null
        ? null
        : InheritedTheme.capture(
            from: context,
            to: Navigator.of(context).context,
          );
    return GlassPageRoute<T>._(
      builder: (context) => themes?.wrap(builder(context)) ?? builder(context),
      spec: spec,
      reduceMotion: reduced,
      settings: settings,
      fullscreenDialog: fullscreenDialog,
    );
  }

  GlassPageRoute._({
    required WidgetBuilder builder,
    required this.spec,
    required bool reduceMotion,
    super.settings,
    super.fullscreenDialog,
  }) : super(
         transitionDuration:
             reduceMotion || spec.transition == GlassTransition.none
             ? Duration.zero
             : spec.duration,
         reverseTransitionDuration:
             reduceMotion || spec.transition == GlassTransition.none
             ? Duration.zero
             : spec.reverseDuration,
         pageBuilder: (context, animation, secondaryAnimation) =>
             builder(context),
         transitionsBuilder: (context, animation, secondaryAnimation, child) =>
             buildGlassTransition(
               animation,
               child,
               spec,
               reduceMotion: reduceMotion || glassReduceMotion(context),
             ),
       );
  final GlassMotionSpec spec;
}
