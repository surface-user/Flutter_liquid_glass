part of '../interaction.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.style,
    EdgeInsetsGeometry? padding,
    this.margin,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
  }) : _padding = padding;
  final Widget child;
  final GlassStyle? style;
  final EdgeInsetsGeometry? _padding;
  EdgeInsetsGeometry get padding => _padding ?? const EdgeInsets.all(20);
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  /// Externally owned focus for interactive cards; ignored when onTap is null.
  final FocusNode? focusNode;
  final bool autofocus;
  @override
  Widget build(BuildContext context) {
    final theme = LiquidGlassTheme.of(context);
    final resolved = style ?? theme.cardStyle;
    final content = Padding(
      padding: _padding ?? glassPadding(context, theme.layout.cardPadding),
      child: DefaultTextStyle.merge(
        style: glassTextStyle(context, theme.textTheme.bodyMedium),
        child: child,
      ),
    );
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: onTap == null
          ? GlassSurface(style: resolved, child: content)
          : _GlassInteraction(
              style: resolved,
              onTap: onTap,
              focusNode: focusNode,
              autofocus: autofocus,
              child: content,
            ),
    );
  }
}
