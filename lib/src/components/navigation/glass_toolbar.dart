import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// A wrapping toolbar; actions and their business meaning belong to the caller.
class GlassToolbar extends StatelessWidget {
  const GlassToolbar({
    super.key,
    required this.children,
    this.spacing,
    this.alignment = WrapAlignment.start,
  }) : assert(spacing == null || (spacing >= 0 && spacing < double.infinity));
  final List<Widget> children;
  final double? spacing;
  final WrapAlignment alignment;
  @override
  Widget build(BuildContext context) {
    final theme = LiquidGlassTheme.of(context);
    final gap =
        spacing ??
        (theme.layout.actionRunSpacing + theme.visualDensity.horizontal * 2)
            .clamp(0, double.infinity);
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      alignment: alignment,
      children: children,
    );
  }
}
