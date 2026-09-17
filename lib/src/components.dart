import 'package:flutter/material.dart';
import 'motion.dart';
import 'style.dart';
import 'surface.dart';
import 'theme.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.style,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.onTap,
  });
  final Widget child;
  final GlassStyle? style;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GlassSurface(
    style: style ?? LiquidGlassTheme.of(context).cardStyle,
    margin: margin,
    child: onTap == null
        ? Padding(padding: padding, child: child)
        : InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
  );
}

/// A null callback disables interaction. Minimum touch target is 48 logical px.
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.style,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.autofocus = false,
    this.focusNode,
  });
  final Widget child;
  final VoidCallback? onPressed;
  final GlassStyle? style;
  final EdgeInsetsGeometry padding;
  final bool autofocus;
  final FocusNode? focusNode;
  @override
  Widget build(BuildContext context) {
    final theme = LiquidGlassTheme.of(context);
    final foreground = theme.brightness == Brightness.dark
        ? Colors.white
        : const Color(0xff17233b);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: GlassSurface(
        style: style ?? theme.buttonStyle,
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        child: InkWell(
          onTap: onPressed,
          autofocus: autofocus,
          focusNode: focusNode,
          canRequestFocus: onPressed != null,
          child: Padding(
            padding: padding,
            child: IconTheme.merge(
              data: IconThemeData(
                color: onPressed == null
                    ? foreground.withValues(alpha: .4)
                    : foreground,
              ),
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  color: onPressed == null
                      ? foreground.withValues(alpha: .4)
                      : foreground,
                  fontWeight: FontWeight.w600,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.style,
  });
  final Widget icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final GlassStyle? style;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: GlassButton(
      onPressed: onPressed,
      style: style,
      padding: const EdgeInsets.all(12),
      child: icon,
    ),
  );
}

/// Use Scaffold.extendBodyBehindAppBar to provide content behind the blur.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.style,
    this.bottom,
    this.toolbarHeight = kToolbarHeight,
    this.automaticallyImplyLeading = true,
  });
  final Widget? title, leading;
  final List<Widget>? actions;
  final GlassStyle? style;
  final PreferredSizeWidget? bottom;
  final double toolbarHeight;
  final bool automaticallyImplyLeading;
  @override
  Size get preferredSize =>
      Size.fromHeight(toolbarHeight + (bottom?.preferredSize.height ?? 0));
  @override
  Widget build(BuildContext context) => GlassSurface(
    style: style ?? LiquidGlassTheme.of(context).appBarStyle,
    child: AppBar(
      title: title,
      leading: leading,
      actions: actions,
      bottom: bottom,
      automaticallyImplyLeading: automaticallyImplyLeading,
      toolbarHeight: toolbarHeight,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
  );
}

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
        glassTransition(context, animation, child, spec, reduceMotion: reduced),
  );
}
