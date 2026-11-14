import 'package:flutter/material.dart';
import '../desktop_style.dart';
import '../../theme/theme.dart';

/// Controlled sidebar/tree row. Indent is presentation, not a tree model.
class GlassNavigationItem extends StatelessWidget {
  const GlassNavigationItem({
    super.key,
    required this.label,
    this.leading,
    this.trailing,
    this.selected = false,
    this.indent = 0,
    this.onPressed,
    this.focusNode,
    this.controlStyle,
  }) : assert(indent >= 0 && indent < double.infinity);
  final String label;
  final Widget? leading, trailing;
  final bool selected;
  final double indent;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final ButtonStyle? controlStyle;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: TextButton(
      onPressed: onPressed,
      focusNode: focusNode,
      style: desktopControlStyle(context, controlStyle, selected: selected),
      child: Padding(
        padding: EdgeInsetsDirectional.only(start: indent),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading!,
              SizedBox(
                width: LiquidGlassTheme.of(context).layout.actionRunSpacing,
              ),
            ],
            Flexible(
              child: Tooltip(
                message: label,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (trailing != null) ...[
              SizedBox(
                width: LiquidGlassTheme.of(context).layout.actionRunSpacing,
              ),
              trailing!,
            ],
          ],
        ),
      ),
    ),
  );
}
