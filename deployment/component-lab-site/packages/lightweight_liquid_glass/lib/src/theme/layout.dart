import 'dart:ui' as ui;
import 'package:flutter/material.dart';

const _unset = Object();

/// Immutable geometry tokens. Null icon/title sizes inherit Flutter defaults.
@immutable
class GlassLayout {
  const GlassLayout({
    this.cardPadding = const EdgeInsets.all(20),
    this.buttonPadding = const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 12,
    ),
    this.iconButtonPadding = const EdgeInsets.all(12),
    this.dialogPadding = const EdgeInsets.all(24),
    this.dialogMaxWidth = 480,
    this.titleSpacing = 16,
    this.actionSpacing = 24,
    this.actionRunSpacing = 12,
    this.iconSize = null,
    this.appBarTitleSpacing = null,
  }) : assert(dialogMaxWidth > 0 && dialogMaxWidth < double.infinity),
       assert(titleSpacing >= 0 && titleSpacing < double.infinity),
       assert(actionSpacing >= 0 && actionSpacing < double.infinity),
       assert(actionRunSpacing >= 0 && actionRunSpacing < double.infinity),
       assert(iconSize == null || (iconSize > 0 && iconSize < double.infinity)),
       assert(
         appBarTitleSpacing == null ||
             (appBarTitleSpacing >= 0 && appBarTitleSpacing < double.infinity),
       );
  final EdgeInsetsGeometry cardPadding;
  final EdgeInsetsGeometry buttonPadding;
  final EdgeInsetsGeometry iconButtonPadding;
  final EdgeInsetsGeometry dialogPadding;
  final double dialogMaxWidth;
  final double titleSpacing;
  final double actionSpacing;
  final double actionRunSpacing;
  final double? iconSize;
  final double? appBarTitleSpacing;

  /// Omit a nullable size to retain it; pass null explicitly to inherit Flutter.
  GlassLayout copyWith({
    EdgeInsetsGeometry? cardPadding,
    EdgeInsetsGeometry? buttonPadding,
    EdgeInsetsGeometry? iconButtonPadding,
    EdgeInsetsGeometry? dialogPadding,
    double? dialogMaxWidth,
    double? titleSpacing,
    double? actionSpacing,
    double? actionRunSpacing,
    Object? iconSize = _unset,
    Object? appBarTitleSpacing = _unset,
  }) => GlassLayout(
    cardPadding: cardPadding ?? this.cardPadding,
    buttonPadding: buttonPadding ?? this.buttonPadding,
    iconButtonPadding: iconButtonPadding ?? this.iconButtonPadding,
    dialogPadding: dialogPadding ?? this.dialogPadding,
    dialogMaxWidth: dialogMaxWidth ?? this.dialogMaxWidth,
    titleSpacing: titleSpacing ?? this.titleSpacing,
    actionSpacing: actionSpacing ?? this.actionSpacing,
    actionRunSpacing: actionRunSpacing ?? this.actionRunSpacing,
    iconSize: identical(iconSize, _unset)
        ? this.iconSize
        : (iconSize as num?)?.toDouble(),
    appBarTitleSpacing: identical(appBarTitleSpacing, _unset)
        ? this.appBarTitleSpacing
        : (appBarTitleSpacing as num?)?.toDouble(),
  );

  static GlassLayout lerp(GlassLayout a, GlassLayout b, double t) =>
      GlassLayout(
        cardPadding: EdgeInsetsGeometry.lerp(a.cardPadding, b.cardPadding, t)!,
        buttonPadding: EdgeInsetsGeometry.lerp(
          a.buttonPadding,
          b.buttonPadding,
          t,
        )!,
        iconButtonPadding: EdgeInsetsGeometry.lerp(
          a.iconButtonPadding,
          b.iconButtonPadding,
          t,
        )!,
        dialogPadding: EdgeInsetsGeometry.lerp(
          a.dialogPadding,
          b.dialogPadding,
          t,
        )!,
        dialogMaxWidth: ui.lerpDouble(a.dialogMaxWidth, b.dialogMaxWidth, t)!,
        titleSpacing: ui.lerpDouble(a.titleSpacing, b.titleSpacing, t)!,
        actionSpacing: ui.lerpDouble(a.actionSpacing, b.actionSpacing, t)!,
        actionRunSpacing: ui.lerpDouble(
          a.actionRunSpacing,
          b.actionRunSpacing,
          t,
        )!,
        iconSize: a.iconSize == null || b.iconSize == null
            ? (t < .5 ? a.iconSize : b.iconSize)
            : ui.lerpDouble(a.iconSize, b.iconSize, t),
        appBarTitleSpacing:
            a.appBarTitleSpacing == null || b.appBarTitleSpacing == null
            ? (t < .5 ? a.appBarTitleSpacing : b.appBarTitleSpacing)
            : ui.lerpDouble(a.appBarTitleSpacing, b.appBarTitleSpacing, t),
      );
}
