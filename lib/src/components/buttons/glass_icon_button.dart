part of '../interaction.dart';

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
