part of '../interaction.dart';

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.style,
    this.controlStyle,
    this.focusNode,
    this.autofocus = false,
  });
  final Widget icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final GlassStyle? style;

  /// State-aware overrides; null fields inherit the nearest control theme.
  final ButtonStyle? controlStyle;

  /// Externally owned; this widget never disposes it.
  final FocusNode? focusNode;
  final bool autofocus;
  @override
  Widget build(BuildContext context) {
    final theme = LiquidGlassTheme.of(context);
    final control = glassControlStyle(context, controlStyle);
    return Tooltip(
      message: tooltip,
      child: GlassButton(
        onPressed: onPressed,
        style: style,
        controlStyle: (controlStyle ?? const ButtonStyle()).copyWith(
          padding: WidgetStateProperty.resolveWith(
            (states) =>
                control.padding?.resolve(states) ??
                glassPadding(
                  context,
                  theme.layout.iconButtonPadding,
                  density: control.visualDensity,
                ),
          ),
        ),
        focusNode: focusNode,
        autofocus: autofocus,
        child: icon,
      ),
    );
  }
}
