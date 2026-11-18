import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';

import '../../theme.dart' show LiquidGlassTheme;
import '../../theme/action_button_theme.dart';

/// A Material-hosted action with an application-owned loading state.
class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.leading,
    this.focusNode,
    this.variant = ActionButtonVariant.secondary,
    this.size = ActionButtonSize.medium,
    this.loading = false,
    this.style,
  }) : _tooltip = null;

  const ActionButton._icon({
    required this.child,
    required this.onPressed,
    required this.focusNode,
    required this.variant,
    required this.size,
    required this.loading,
    required this.style,
    required String tooltip,
  }) : leading = null,
       _tooltip = tooltip;

  /// The non-interactive button content, usually a text label.
  final Widget child;

  /// The action to request. Null disables the button, even during loading.
  final VoidCallback? onPressed;

  /// An optional decorative icon before the content.
  final Widget? leading;

  /// A caller-owned focus node. The button does not dispose it.
  final FocusNode? focusNode;

  /// The role of the button, independent of its size and surrounding surface.
  final ActionButtonVariant variant;

  /// The minimum visual size and content spacing.
  final ActionButtonSize size;

  /// Shows progress and blocks activation without changing layout or focus.
  final bool loading;

  /// Per-field visual overrides for this instance.
  final ActionButtonStyle? style;

  final String? _tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final scopedStyle = ActionButtonTheme.of(context, variant);
    final highContrast =
        MediaQuery.highContrastOf(context) ||
        LiquidGlassTheme.of(context).accessibility.highContrast;
    final busy = loading && onPressed != null;
    final (fill, foreground) = switch (variant) {
      ActionButtonVariant.primary => (colors.primary, colors.onPrimary),
      ActionButtonVariant.secondary => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
      ),
      ActionButtonVariant.auxiliary => (Colors.transparent, colors.primary),
    };
    final disabledFill = fill == Colors.transparent
        ? fill
        : colors.onSurface.withValues(alpha: 0.12);
    final foregroundColor = WidgetStateProperty.resolveWith<Color>(
      (states) => states.contains(WidgetState.disabled)
          ? colors.onSurface.withValues(alpha: highContrast ? 1 : 0.38)
          : foreground,
    );
    final (minHeight, horizontalPadding) = switch (size) {
      ActionButtonSize.small => (48.0, 12.0),
      ActionButtonSize.medium => (52.0, 16.0),
      ActionButtonSize.large => (56.0, 20.0),
    };
    final radius =
        style?.borderRadius ??
        scopedStyle.borderRadius ??
        const BorderRadius.all(Radius.circular(8));
    final outlineColor = highContrast
        ? foreground
        : style?.focusBorderColor ?? scopedStyle.focusBorderColor ?? foreground;
    final tooltip = _tooltip;
    final content = tooltip != null
        ? Semantics(
            label: tooltip,
            child: ExcludeSemantics(child: child),
          )
        : leading == null
        ? child
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(child: leading!),
              const SizedBox(width: 8),
              Flexible(child: child),
            ],
          );

    final button = Semantics(
      blockUserActions: busy,
      child: TextButton(
        onPressed: onPressed == null
            ? null
            : () {
                if (!busy) onPressed!.call();
              },
        focusNode: focusNode,
        style: ButtonStyle(
          foregroundColor: foregroundColor,
          iconColor: foregroundColor,
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) return disabledFill;
            final feedback = busy
                ? 0.0
                : states.contains(WidgetState.pressed)
                ? 0.12
                : states.contains(WidgetState.hovered)
                ? 0.08
                : 0.0;
            return Color.alphaBlend(
              foreground.withValues(alpha: feedback),
              fill,
            );
          }),
          side: WidgetStateProperty.resolveWith<BorderSide>(
            (states) => states.contains(WidgetState.focused)
                ? BorderSide(width: 2, color: outlineColor)
                : BorderSide.none,
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: radius),
          ),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: tooltip == null ? horizontalPadding : 8,
              vertical: 8,
            ),
          ),
          minimumSize: WidgetStatePropertyAll(
            Size(tooltip == null ? 48 : minHeight, minHeight),
          ),
          visualDensity: VisualDensity.standard,
          tapTargetSize: MaterialTapTargetSize.padded,
          animationDuration: Duration.zero,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
          enableFeedback: !busy,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            IgnorePointer(
              child: Opacity(
                opacity: busy ? 0 : 1,
                alwaysIncludeSemantics: true,
                child: content,
              ),
            ),
            if (busy)
              Positioned.fill(
                child: Center(
                  child: Semantics(
                    container: true,
                    role: SemanticsRole.loadingSpinner,
                    child: const Icon(Icons.hourglass_empty, size: 18),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    return AbsorbPointer(
      absorbing: busy,
      child: tooltip == null
          ? button
          : Tooltip(
              message: tooltip,
              excludeFromSemantics: true,
              child: button,
            ),
    );
  }
}

/// An action button with an icon and a required accessible label.
class IconActionButton extends StatelessWidget {
  const IconActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.focusNode,
    this.variant = ActionButtonVariant.secondary,
    this.size = ActionButtonSize.medium,
    this.loading = false,
    this.style,
  }) : assert(tooltip != '');

  final Widget icon;

  /// The tooltip and accessible name for the icon action.
  final String tooltip;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final ActionButtonVariant variant;
  final ActionButtonSize size;
  final bool loading;
  final ActionButtonStyle? style;

  @override
  Widget build(BuildContext context) => ActionButton._icon(
    child: icon,
    tooltip: tooltip,
    onPressed: onPressed,
    focusNode: focusNode,
    variant: variant,
    size: size,
    loading: loading,
    style: style,
  );
}
