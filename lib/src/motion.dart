import 'package:flutter/material.dart';
import 'theme.dart';

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
             glassTransition(
               context,
               animation,
               child,
               spec,
               reduceMotion: reduceMotion,
             ),
       );
  final GlassMotionSpec spec;
}

Widget glassTransition(
  BuildContext context,
  Animation<double> animation,
  Widget child,
  GlassMotionSpec spec, {
  bool reduceMotion = false,
}) {
  if (reduceMotion ||
      glassReduceMotion(context) ||
      spec.transition == GlassTransition.none) {
    return child;
  }
  return _GlassRouteTransition(animation: animation, spec: spec, child: child);
}

class _GlassRouteTransition extends StatefulWidget {
  const _GlassRouteTransition({
    required this.animation,
    required this.spec,
    required this.child,
  });

  final Animation<double> animation;
  final GlassMotionSpec spec;
  final Widget child;

  @override
  State<_GlassRouteTransition> createState() => _GlassRouteTransitionState();
}

class _GlassRouteTransitionState extends State<_GlassRouteTransition> {
  // The route keeps the same animation and spec throughout its lifetime.
  late final _progress = CurvedAnimation(
    parent: widget.animation,
    curve: widget.spec.curve,
    reverseCurve: widget.spec.reverseCurve,
  );

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget result = widget.child;
    switch (widget.spec.transition) {
      case GlassTransition.fadeSlide:
        result = SlideTransition(
          position: Tween(
            begin: const Offset(0, .035),
            end: Offset.zero,
          ).animate(_progress),
          child: result,
        );
      case GlassTransition.scaleFade:
        result = ScaleTransition(
          scale: Tween(begin: .97, end: 1.0).animate(_progress),
          child: result,
        );
      case GlassTransition.sharedAxis:
        result = SlideTransition(
          position: Tween(
            begin: const Offset(.06, 0),
            end: Offset.zero,
          ).animate(_progress),
          child: result,
        );
        result = ScaleTransition(
          scale: Tween(begin: .98, end: 1.0).animate(_progress),
          child: result,
        );
      case GlassTransition.fade:
      case GlassTransition.none:
        break;
    }
    return FadeTransition(opacity: _progress, child: result);
  }
}
