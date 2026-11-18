import 'package:flutter/material.dart';

/// Overrides the colors used by navigation items.
///
/// Register this in [ThemeData.extensions] for application-wide defaults,
/// or pass it to [NavigationItemTheme] for a subtree.
@immutable
class NavigationItemThemeData extends ThemeExtension<NavigationItemThemeData> {
  const NavigationItemThemeData({
    this.selectedBackgroundColor,
    this.focusBorderColor,
  });

  /// The selected item's base fill, before hover or press feedback.
  ///
  /// Null inherits, with [ColorScheme.secondaryContainer] as the last fallback.
  final Color? selectedBackgroundColor;

  /// The outline shown when a navigation item has focus.
  ///
  /// Null inherits, falling back to the item's foreground color.
  final Color? focusBorderColor;

  /// Copies this configuration. A null argument keeps the current field.
  @override
  NavigationItemThemeData copyWith({
    Color? selectedBackgroundColor,
    Color? focusBorderColor,
  }) => NavigationItemThemeData(
    selectedBackgroundColor:
        selectedBackgroundColor ?? this.selectedBackgroundColor,
    focusBorderColor: focusBorderColor ?? this.focusBorderColor,
  );

  /// Switches at the midpoint so unset colors remain unset during transitions.
  @override
  NavigationItemThemeData lerp(NavigationItemThemeData? other, double t) =>
      t < 0.5 ? this : other ?? this;

  NavigationItemThemeData _withFallback(NavigationItemThemeData? fallback) =>
      fallback?.copyWith(
        selectedBackgroundColor: selectedBackgroundColor,
        focusBorderColor: focusBorderColor,
      ) ??
      this;
}

/// Applies partial navigation item color overrides to [child].
///
/// Unset fields inherit from enclosing [NavigationItemTheme] widgets, nearest
/// first, and then from the ambient [ThemeData.extensions].
class NavigationItemTheme extends StatelessWidget {
  const NavigationItemTheme({
    super.key,
    required this.data,
    required this.child,
  });

  /// The fields this subtree overrides.
  final NavigationItemThemeData data;

  /// The subtree that receives these overrides.
  final Widget child;

  /// Reads local and global overrides. Items supply defaults for unset fields.
  static NavigationItemThemeData of(BuildContext context) {
    final global = Theme.of(context).extension<NavigationItemThemeData>();
    final local = _NavigationItemThemeScope.maybeOf(context);
    return local?._withFallback(global) ??
        global ??
        const NavigationItemThemeData();
  }

  @override
  Widget build(BuildContext context) => _NavigationItemThemeScope(
    data: data._withFallback(_NavigationItemThemeScope.maybeOf(context)),
    child: child,
  );
}

class _NavigationItemThemeScope extends InheritedTheme {
  const _NavigationItemThemeScope({required this.data, required super.child});

  final NavigationItemThemeData data;

  static NavigationItemThemeData? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_NavigationItemThemeScope>()
      ?.data;

  @override
  bool updateShouldNotify(_NavigationItemThemeScope oldWidget) =>
      oldWidget.data.selectedBackgroundColor != data.selectedBackgroundColor ||
      oldWidget.data.focusBorderColor != data.focusBorderColor;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      _NavigationItemThemeScope(data: data, child: child);
}
