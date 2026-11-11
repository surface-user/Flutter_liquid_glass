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
    this.padding,
    this.constraints,
  });
  final Widget? title;
  final Widget content;
  final List<Widget> actions;
  final GlassStyle? style;
  final String? semanticLabel;

  /// Explicit values override the nearest geometry configuration.
  final EdgeInsetsGeometry? padding;

  /// Defaults to the themed maximum width, without a fixed height.
  final BoxConstraints? constraints;
  @override
  Widget build(BuildContext context) {
    final theme = LiquidGlassTheme.of(context);
    final surfaceConstraints =
        constraints ?? BoxConstraints(maxWidth: theme.layout.dialogMaxWidth);
    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      constraints:
          constraints ??
          (DialogTheme.of(context).constraints ??
                  const BoxConstraints(minWidth: 280))
              .enforce(surfaceConstraints),
      child: Semantics(
        namesRoute: true,
        label: semanticLabel,
        child: GlassSurface(
          style: style ?? theme.dialogStyle,
          constraints: surfaceConstraints,
          padding: padding ?? glassPadding(context, theme.layout.dialogPadding),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  DefaultTextStyle.merge(
                    style: Theme.of(context).textTheme.headlineSmall!.merge(
                      glassTextStyle(
                        context,
                        theme.textTheme.headlineSmall,
                        inheritedStyle: Theme.of(context).textTheme.bodyMedium!
                            .merge(Theme.of(context).textTheme.headlineSmall),
                      ),
                    ),
                    child: title!,
                  ),
                  SizedBox(height: theme.layout.titleSpacing),
                ],
                DefaultTextStyle.merge(
                  style: glassTextStyle(context, theme.textTheme.bodyMedium),
                  child: content,
                ),
                if (actions.isNotEmpty) ...[
                  SizedBox(height: theme.layout.actionSpacing),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: theme.layout.actionRunSpacing,
                      runSpacing: theme.layout.actionRunSpacing,
                      children: actions,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
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
