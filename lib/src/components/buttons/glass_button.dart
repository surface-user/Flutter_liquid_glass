part of '../interaction.dart';

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
