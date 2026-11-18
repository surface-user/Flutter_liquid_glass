import 'package:flutter/material.dart';

/// The role of an action in its surrounding interface.
enum ActionButtonVariant { primary, secondary, auxiliary }

/// The size of an action button. Each size retains a 48dp minimum target.
enum ActionButtonSize { small, medium, large }

/// Partial visual overrides for action buttons; null fields inherit.
@immutable
class ActionButtonStyle {
  const ActionButtonStyle({this.borderRadius, this.focusBorderColor});

  /// Overrides corner rounding. [BorderRadius.zero] makes square corners.
  final BorderRadiusGeometry? borderRadius;

  /// Overrides the focus outline, except in high-contrast mode.
  final Color? focusBorderColor;

  ActionButtonStyle _withFallback(ActionButtonStyle fallback) =>
      ActionButtonStyle(
        borderRadius: borderRadius ?? fallback.borderRadius,
        focusBorderColor: focusBorderColor ?? fallback.focusBorderColor,
      );
}

/// Global or subtree defaults for both action buttons and icon action buttons.
///
/// A variant's non-null fields take priority over general [style] fields at
/// this scope. A nearer scope still takes priority over a farther variant.
@immutable
class ActionButtonThemeData extends ThemeExtension<ActionButtonThemeData> {
  const ActionButtonThemeData({
    this.style = const ActionButtonStyle(),
    this.primary = const ActionButtonStyle(),
    this.secondary = const ActionButtonStyle(),
    this.auxiliary = const ActionButtonStyle(),
  });

  final ActionButtonStyle style;
  final ActionButtonStyle primary;
  final ActionButtonStyle secondary;
  final ActionButtonStyle auxiliary;

  /// Replaces supplied style groups and keeps omitted groups.
  @override
  ActionButtonThemeData copyWith({
    ActionButtonStyle? style,
    ActionButtonStyle? primary,
    ActionButtonStyle? secondary,
    ActionButtonStyle? auxiliary,
  }) => ActionButtonThemeData(
    style: style ?? this.style,
    primary: primary ?? this.primary,
    secondary: secondary ?? this.secondary,
    auxiliary: auxiliary ?? this.auxiliary,
  );

  /// Switches at the midpoint, keeping absent fields absent.
  @override
  ActionButtonThemeData lerp(ActionButtonThemeData? other, double t) =>
      t < 0.5 ? this : other ?? this;

  ActionButtonStyle _forVariant(ActionButtonVariant variant) =>
      (switch (variant) {
        ActionButtonVariant.primary => primary,
        ActionButtonVariant.secondary => secondary,
        ActionButtonVariant.auxiliary => auxiliary,
      })._withFallback(style);
}

/// Applies action button defaults to a subtree.
///
/// Missing fields inherit from outer scopes, then from [ThemeData.extensions].
class ActionButtonTheme extends StatelessWidget {
  const ActionButtonTheme({super.key, required this.data, required this.child});

  final ActionButtonThemeData data;
  final Widget child;

  /// Resolves inherited overrides for [variant], without widget defaults.
  static ActionButtonStyle of(
    BuildContext context,
    ActionButtonVariant variant,
  ) {
    final global = Theme.of(context).extension<ActionButtonThemeData>();
    final local = _ActionButtonThemeScope.maybeOf(context);
    final fallback = global?._forVariant(variant) ?? const ActionButtonStyle();
    return local?._forVariant(variant)._withFallback(fallback) ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final parent = _ActionButtonThemeScope.maybeOf(context);
    ActionButtonStyle resolve(ActionButtonVariant variant) => data
        ._forVariant(variant)
        ._withFallback(
          parent?._forVariant(variant) ?? const ActionButtonStyle(),
        );

    return _ActionButtonThemeScope(
      data: ActionButtonThemeData(
        primary: resolve(ActionButtonVariant.primary),
        secondary: resolve(ActionButtonVariant.secondary),
        auxiliary: resolve(ActionButtonVariant.auxiliary),
      ),
      child: child,
    );
  }
}

class _ActionButtonThemeScope extends InheritedTheme {
  const _ActionButtonThemeScope({required this.data, required super.child});

  final ActionButtonThemeData data;

  static ActionButtonThemeData? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_ActionButtonThemeScope>()
      ?.data;

  @override
  bool updateShouldNotify(_ActionButtonThemeScope oldWidget) =>
      ActionButtonVariant.values.any((variant) {
        final old = oldWidget.data._forVariant(variant);
        final next = data._forVariant(variant);
        return old.borderRadius != next.borderRadius ||
            old.focusBorderColor != next.focusBorderColor;
      });

  @override
  Widget wrap(BuildContext context, Widget child) =>
      _ActionButtonThemeScope(data: data, child: child);
}
