import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// A themed SDK text field. The SDK owns implicit state; supplied controllers
/// and focus nodes remain owned by the caller. Search uses InputDecoration.
class GlassTextField extends StatelessWidget {
  const GlassTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.enabled,
    this.readOnly = false,
    this.autofocus = false,
    this.decoration = const InputDecoration(),
    this.style,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
  });
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool? enabled;
  final bool readOnly, autofocus;
  final InputDecoration decoration;
  final TextStyle? style;
  final ValueChanged<String>? onChanged, onSubmitted;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final theme = LiquidGlassTheme.of(context);
    final material = Theme.of(context);
    final contrast =
        theme.accessibility.highContrast ||
        MediaQuery.maybeOf(context)?.highContrast == true;
    final foreground = contrast
        ? (theme.brightness == Brightness.dark
              ? Colors.white
              : const Color(0xff17233b))
        : theme.foregroundColor;
    final colors = theme.colorScheme ?? material.colorScheme;
    final border = OutlineInputBorder(
      borderRadius: theme.buttonStyle.borderRadius,
      borderSide: BorderSide(
        color: contrast ? foreground : colors.outline,
        width: contrast ? 2 : 1,
      ),
    );
    final provided = decoration.applyDefaults(material.inputDecorationTheme);
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled ?? decoration.enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: textInputAction,
      cursorColor: contrast ? foreground : theme.focusColor,
      style: glassTextStyle(
        context,
        material.textTheme.bodyLarge!
            .merge(theme.textTheme.bodyMedium)
            .merge(style),
      ),
      decoration: provided.copyWith(
        filled: contrast ? true : provided.filled ?? true,
        fillColor: contrast
            ? (theme.brightness == Brightness.dark
                  ? const Color(0xff202a3c)
                  : const Color(0xffedf1f8))
            : provided.fillColor ?? theme.surfaceColor,
        contentPadding:
            provided.contentPadding ??
            glassPadding(context, theme.layout.buttonPadding),
        isDense:
            provided.isDense ?? theme.visualDensity != VisualDensity.standard,
        labelStyle: contrast
            ? (provided.labelStyle ?? const TextStyle()).copyWith(
                color: foreground,
              )
            : provided.labelStyle,
        floatingLabelStyle: contrast
            ? (provided.floatingLabelStyle ?? const TextStyle()).copyWith(
                color: foreground,
              )
            : provided.floatingLabelStyle,
        hintStyle: contrast
            ? (provided.hintStyle ?? const TextStyle()).copyWith(
                color: foreground,
              )
            : provided.hintStyle,
        helperStyle: contrast
            ? (provided.helperStyle ?? const TextStyle()).copyWith(
                color: foreground,
              )
            : provided.helperStyle,
        errorStyle: contrast
            ? (provided.errorStyle ?? const TextStyle()).copyWith(
                color: foreground,
              )
            : provided.errorStyle,
        prefixStyle: contrast
            ? (provided.prefixStyle ?? const TextStyle()).copyWith(
                color: foreground,
              )
            : provided.prefixStyle,
        suffixStyle: contrast
            ? (provided.suffixStyle ?? const TextStyle()).copyWith(
                color: foreground,
              )
            : provided.suffixStyle,
        prefixIconColor: contrast ? foreground : provided.prefixIconColor,
        suffixIconColor: contrast ? foreground : provided.suffixIconColor,
        border: contrast ? border : provided.border ?? border,
        enabledBorder: contrast ? border : provided.enabledBorder ?? border,
        disabledBorder: contrast ? border : provided.disabledBorder ?? border,
        focusedBorder: contrast
            ? border
            : provided.focusedBorder ??
                  border.copyWith(
                    borderSide: BorderSide(color: theme.focusColor, width: 2),
                  ),
        errorBorder: contrast
            ? border
            : provided.errorBorder ??
                  border.copyWith(borderSide: BorderSide(color: colors.error)),
        focusedErrorBorder: contrast
            ? border
            : provided.focusedErrorBorder ??
                  border.copyWith(
                    borderSide: BorderSide(color: colors.error, width: 2),
                  ),
      ),
    );
  }
}
