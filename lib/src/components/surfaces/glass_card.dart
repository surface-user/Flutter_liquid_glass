part of '../interaction.dart';

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
