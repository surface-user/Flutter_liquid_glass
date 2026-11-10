import 'package:flutter/material.dart';
import '../../core/motion_spec.dart';
import '../../core/style.dart';
import '../../core/transitions.dart';
import '../../theme/theme.dart';
import '../surfaces/glass_surface.dart';

class GlassDialog extends StatelessWidget {
  const GlassDialog({
    super.key,
    this.title,
    required this.content,
    this.actions = const [],
    this.style,
    this.semanticLabel,
  });
  final Widget? title;
  final Widget content;
  final List<Widget> actions;
  final GlassStyle? style;
  final String? semanticLabel;
  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    child: Semantics(
      namesRoute: true,
      label: semanticLabel,
      child: GlassSurface(
        style: style ?? LiquidGlassTheme.of(context).dialogStyle,
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                DefaultTextStyle.merge(
                  style: Theme.of(context).textTheme.headlineSmall!,
                  child: title!,
                ),
                const SizedBox(height: 16),
              ],
              content,
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(spacing: 12, runSpacing: 12, children: actions),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

/// Captures inherited themes so local glass overrides survive the new route.
Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  GlassMotionSpec? motion,
}) {
  final theme = LiquidGlassTheme.of(context);
  final spec = motion ?? theme.motion;
  final reduced = glassReduceMotion(context);
  final themes = InheritedTheme.capture(
    from: context,
    to: Navigator.of(context, rootNavigator: useRootNavigator).context,
  );
  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: .32),
    routeSettings: routeSettings,
    transitionDuration: reduced || spec.transition == GlassTransition.none
        ? Duration.zero
        : spec.duration,
    pageBuilder: (context, animation, secondaryAnimation) => themes.wrap(
      LiquidGlassTheme(
        data: theme,
        child: SafeArea(child: Builder(builder: builder)),
      ),
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) =>
        buildGlassTransition(
          animation,
          child,
          spec,
          reduceMotion: reduced || glassReduceMotion(context),
        ),
  );
}
