import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';

import '../../theme/action_button_theme.dart';
import '../../theme/navigation_item_theme.dart';
import '../actions/action_button.dart';

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
  }) : _isTab = false;

  const NavigationItem._tab({
    required this.label,
    required this.selected,
    required this.onPressed,
    required this.focusNode,
  }) : _isTab = true,
       leading = null,
       trailing = null;

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

  final bool _isTab;

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
      isSemanticButton: !_isTab,
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
        role: _isTab ? SemanticsRole.tab : null,
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

/// A controlled navigation tab with an optional independent close action.
///
/// The caller owns selection, decides whether to close, and manages the
/// corresponding page. The tab can be used on a regular or glass surface.
class NavigationTab extends StatelessWidget {
  const NavigationTab({
    super.key,
    required this.label,
    this.selected = false,
    this.onPressed,
    this.onClose,
    this.closeTooltip,
    this.focusNode,
  }) : assert(
         onClose == null || (closeTooltip != null && closeTooltip != ''),
         'A closable tab needs a non-empty closeTooltip.',
       );

  /// The visible label and accessible name of the tab.
  final String label;

  /// Whether the caller considers this tab selected.
  final bool selected;

  /// Requests selection. Null disables the tab without disabling its close
  /// button.
  final VoidCallback? onPressed;

  /// Requests closure without changing selection. Null hides the close button.
  final VoidCallback? onClose;

  /// The localized name of the close button, required when [onClose] is set.
  final String? closeTooltip;

  /// A caller-owned focus node for the main tab, not its close button.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(
        child: NavigationItem._tab(
          label: label,
          selected: selected,
          onPressed: onPressed,
          focusNode: focusNode,
        ),
      ),
      if (onClose != null)
        IconActionButton(
          icon: const Icon(Icons.close),
          tooltip: switch (closeTooltip) {
            final label? when label.isNotEmpty => label,
            _ => MaterialLocalizations.of(context).closeButtonTooltip,
          },
          size: ActionButtonSize.small,
          variant: ActionButtonVariant.auxiliary,
          onPressed: onClose,
        ),
    ],
  );
}
