part of '../interaction.dart';

/// Null disables interaction. Default touch targets are 48 logical px;
/// compact desktop targets require explicit shrinkWrap configuration.
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.style,
    EdgeInsetsGeometry? padding,
    this.autofocus = false,
    this.focusNode,
    this.controlStyle,
  }) : _padding = padding;
  final Widget child;
  final VoidCallback? onPressed;
  final GlassStyle? style;
  final EdgeInsetsGeometry? _padding;

  /// The legacy default; omitted values resolve through the theme when built.
  EdgeInsetsGeometry get padding =>
      _padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12);

  /// Per-control state/geometry overrides, merged over the nearest theme.
  final ButtonStyle? controlStyle;
  final bool autofocus;
  final FocusNode? focusNode;
  @override
  Widget build(BuildContext context) {
    final theme = LiquidGlassTheme.of(context);
    final control = glassControlStyle(context, controlStyle);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: _GlassInteraction(
        style: style ?? theme.buttonStyle,
        onTap: onPressed,
        autofocus: autofocus,
        focusNode: focusNode,
        controlStyle: control,
        materialControlStyle: style == null ? control : controlStyle,
        contentBuilder: (states) {
          final highContrast =
              theme.accessibility.highContrast ||
              MediaQuery.maybeOf(context)?.highContrast == true;
          final contrastColor = theme.brightness == Brightness.dark
              ? Colors.white
              : const Color(0xff17233b);
          final foreground = highContrast
              ? (onPressed == null
                    ? contrastColor.withValues(alpha: .4)
                    : contrastColor)
              : control.foregroundColor?.resolve(states) ??
                    control.textStyle?.resolve(states)?.color ??
                    theme.textTheme.labelLarge?.color ??
                    (onPressed == null
                        ? theme.foregroundColor.withValues(alpha: .4)
                        : theme.foregroundColor);
          final density = control.visualDensity ?? theme.visualDensity;
          final minimum =
              control.minimumSize?.resolve(states) ?? const Size(48, 48);
          final target =
              (control.tapTargetSize ?? theme.tapTargetSize) ==
                  MaterialTapTargetSize.padded
              ? 48.0
              : 0.0;
          final themedPadding = control.padding?.resolve(states);
          return ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: math.max(
                target,
                minimum.width + density.baseSizeAdjustment.dx,
              ),
              minHeight: math.max(
                target,
                minimum.height + density.baseSizeAdjustment.dy,
              ),
            ),
            child: Padding(
              padding:
                  _padding ??
                  themedPadding ??
                  glassPadding(
                    context,
                    theme.layout.buttonPadding,
                    density: density,
                  ),
              child: IconTheme.merge(
                data: IconThemeData(
                  color: foreground,
                  size:
                      control.iconSize?.resolve(states) ??
                      theme.layout.iconSize,
                ),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(fontWeight: FontWeight.w600)
                      .merge(theme.textTheme.labelLarge)
                      .merge(control.textStyle?.resolve(states))
                      .copyWith(color: foreground),
                  child: child,
                ),
              ),
            ),
          );
        },
        child: child,
      ),
    );
  }
}
