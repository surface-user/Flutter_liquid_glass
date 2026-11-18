import 'package:flutter/material.dart';

import '../../theme/navigation_item_theme.dart';

/// An independent navigation item for use inside a caller-owned layout.
///
/// The caller owns selection and decides what activation does. This item
/// works on a regular Material surface or inside a separate glass surface.
class NavigationItem extends StatelessWidget {
  const NavigationItem({
    super.key,
    required this.label,
    this.leading,
    this.trailing,
    this.selected = false,
    this.onPressed,
    this.focusNode,
  });

  /// The visible label. Long labels are shortened and available in a tooltip.
  final String label;

  /// Optional non-interactive content before the label, such as an icon.
  final Widget? leading;

  /// Optional non-interactive content after the label, such as a badge.
  final Widget? trailing;

  /// Whether the caller currently considers this destination selected.
  final bool selected;

  /// Requests activation. If null, the item is disabled.
  final VoidCallback? onPressed;

  /// An optional focus node that the caller owns and disposes.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme = NavigationItemTheme.of(context);
    final foreground = selected
        ? colors.onSecondaryContainer
        : colors.onSurface;
    final foregroundColor = WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? colors.onSurface.withValues(alpha: 0.38)
          : foreground,
    );
    return TextButton(
      onPressed: onPressed,
      focusNode: focusNode,
      style: ButtonStyle(
        alignment: AlignmentDirectional.centerStart,
        padding: const WidgetStatePropertyAll(
          EdgeInsetsDirectional.fromSTEB(12, 8, 12, 8),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        visualDensity: VisualDensity.standard,
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        animationDuration: Duration.zero,
        splashFactory: NoSplash.splashFactory,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        foregroundColor: foregroundColor,
        iconColor: foregroundColor,
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          final base = selected
              ? theme.selectedBackgroundColor ?? colors.secondaryContainer
              : Colors.transparent;
          if (states.contains(WidgetState.disabled)) return base;
          final opacity = states.contains(WidgetState.pressed)
              ? 0.12
              : states.contains(WidgetState.hovered)
              ? 0.08
              : 0.0;
          return Color.alphaBlend(foreground.withValues(alpha: opacity), base);
        }),
        side: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? BorderSide(
                  color: theme.focusBorderColor ?? foreground,
                  width: 2,
                )
              : BorderSide.none,
        ),
      ),
      child: Semantics(
        selected: selected,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 8)],
            Flexible(
              child: Tooltip(
                message: label,
                excludeFromSemantics: true,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}
