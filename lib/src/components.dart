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
  Widget build(BuildContext context) {
    final resolved = style ?? LiquidGlassTheme.of(context).cardStyle;
    final content = Padding(padding: padding, child: child);
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: onTap == null
          ? GlassSurface(style: resolved, child: content)
          : _GlassInteraction(style: resolved, onTap: onTap, child: content),
    );
  }
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
      child: _GlassInteraction(
        style: style ?? theme.buttonStyle,
        onTap: onPressed,
        autofocus: autofocus,
        focusNode: focusNode,
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
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

class _GlassInteraction extends StatefulWidget {
  const _GlassInteraction({
    required this.style,
    required this.onTap,
    required this.child,
    this.constraints,
    this.autofocus = false,
    this.focusNode,
  });
  final GlassStyle style;
  final VoidCallback? onTap;
  final Widget child;
  final BoxConstraints? constraints;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  State<_GlassInteraction> createState() => _GlassInteractionState();
}

class _GlassInteractionState extends State<_GlassInteraction> {
  bool pressed = false, hovered = false, focused = false;

  @override
  void didUpdateWidget(_GlassInteraction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onTap == null) pressed = hovered = focused = false;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final down = enabled && pressed;
    final focus = enabled && focused;
    final hover = enabled && hovered;
    final reduced = glassReduceMotion(context);
    final s = widget.style;
    final amount = down ? .05 : (focus ? .02 : (hover ? .03 : 0.0));
    final style = s.copyWith(
      tintOpacity: (s.tintOpacity + amount).clamp(0, 1),
      highlightOpacity: (s.highlightOpacity + amount).clamp(0, 1),
      borderWidth: focus ? s.borderWidth + 2 : s.borderWidth,
      borderColor: focus
          ? LiquidGlassTheme.of(context).accentColor
          : s.borderColor,
      borderOpacity: focus ? 1 : s.borderOpacity,
      borderGradient: focus ? null : s.borderGradient,
      shadowOffset: down ? s.shadowOffset * .5 : s.shadowOffset,
    );
    // Transformed surfaces may overlap neighbours, so isolate their backdrop input.
    final surface = GlassGroup(
      overlapping: true,
      child: GlassSurface(
        style: style,
        constraints: widget.constraints,
        child: InkWell(
          onTap: widget.onTap,
          autofocus: widget.autofocus,
          focusNode: widget.focusNode,
          canRequestFocus: enabled,
          onHighlightChanged: (value) {
            if (widget.onTap != null && pressed != value) {
              setState(() => pressed = value);
            }
          },
          onHover: (value) => setState(() => hovered = value),
          onFocusChange: (value) => setState(() => focused = value),
          child: widget.child,
        ),
      ),
    );
    // Keep the InkWell mounted so motion changes cannot interrupt gesture cleanup.
    return TweenAnimationBuilder<double>(
      tween: Tween(
        end: reduced || !enabled
            ? 0.0
            : (down ? -1.0 : (focus ? 0.0 : (hover ? .5 : 0.0))),
      ),
      duration: reduced || !enabled
          ? Duration.zero
          : Duration(milliseconds: down ? 90 : (hover ? 160 : 180)),
      curve: Curves.easeOutCubic,
      child: surface,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, value < 0 ? -value * 1.5 : 0),
        child: Transform.scale(scale: 1 + value * .02, child: child),
      ),
    );
  }
}
