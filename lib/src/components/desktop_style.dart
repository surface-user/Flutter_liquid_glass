import 'package:flutter/material.dart';
import '../theme/theme.dart';

// Shared styling for SDK desktop controls; no backdrop filter per item.
ButtonStyle desktopControlStyle(
  BuildContext context,
  ButtonStyle? local, {
  bool selected = false,
  bool icon = false,
}) {
  final theme = LiquidGlassTheme.of(context);
  final control = glassControlStyle(context, local);
  final contrast =
      theme.accessibility.highContrast ||
      MediaQuery.maybeOf(context)?.highContrast == true;
  final foreground = contrast
      ? (theme.brightness == Brightness.dark
            ? Colors.white
            : const Color(0xff17233b))
      : theme.foregroundColor;
  final focus = contrast ? foreground : theme.focusColor;
  Set<WidgetState> states(Set<WidgetState> value) => {
    ...value,
    if (selected) WidgetState.selected,
  };
  return control.copyWith(
    alignment: control.alignment ?? AlignmentDirectional.centerStart,
    foregroundColor: WidgetStateProperty.resolveWith(
      (value) => contrast
          ? foreground
          : control.foregroundColor?.resolve(states(value)) ??
                (value.contains(WidgetState.disabled)
                    ? foreground.withValues(alpha: .4)
                    : foreground),
    ),
    backgroundColor: WidgetStateProperty.resolveWith(
      (value) => contrast
          ? (theme.brightness == Brightness.dark
                ? const Color(0xff202a3c)
                : const Color(0xffedf1f8))
          : control.backgroundColor?.resolve(states(value)) ??
                (selected ? focus.withValues(alpha: .12) : Colors.transparent),
    ),
    overlayColor: WidgetStateProperty.resolveWith(
      (value) =>
          (!contrast ? control.overlayColor?.resolve(states(value)) : null) ??
          (value.any(
                {
                  WidgetState.pressed,
                  WidgetState.hovered,
                  WidgetState.focused,
                }.contains,
              )
              ? focus.withValues(alpha: .10)
              : Colors.transparent),
    ),
    textStyle: WidgetStateProperty.resolveWith(
      (value) => Theme.of(context).textTheme.labelLarge!
          .copyWith(fontWeight: FontWeight.w600)
          .merge(theme.textTheme.labelLarge)
          .merge(control.textStyle?.resolve(states(value))),
    ),
    iconSize: WidgetStateProperty.resolveWith(
      (value) =>
          control.iconSize?.resolve(states(value)) ??
          theme.layout.iconSize ??
          24,
    ),
    padding: WidgetStateProperty.resolveWith(
      (value) =>
          control.padding?.resolve(states(value)) ??
          glassPadding(
            context,
            icon ? theme.layout.iconButtonPadding : theme.layout.buttonPadding,
            density: control.visualDensity,
          ),
    ),
    minimumSize: WidgetStateProperty.resolveWith(
      (value) =>
          control.minimumSize?.resolve(states(value)) ??
          Size(icon ? 48 : 0, 48),
    ),
    side: WidgetStateProperty.resolveWith((value) {
      final side = control.side?.resolve(states(value));
      if (value.contains(WidgetState.focused))
        return BorderSide(color: focus, width: 2);
      return contrast
          ? BorderSide(color: foreground)
          : side ?? BorderSide(color: selected ? focus : Colors.transparent);
    }),
    shape:
        control.shape ?? const WidgetStatePropertyAll(RoundedRectangleBorder()),
    visualDensity: control.visualDensity ?? theme.visualDensity,
    tapTargetSize: control.tapTargetSize ?? theme.tapTargetSize,
    animationDuration: glassReduceMotion(context)
        ? Duration.zero
        : control.animationDuration ?? theme.motion.hoverDuration,
  );
}
