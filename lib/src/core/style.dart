import 'dart:ui' as ui;
import 'package:flutter/material.dart';

const _unset = Object();

/// Immutable glass appearance. Angles are radians; opacity values are 0–1.
/// Saturation and contrast affect the backdrop only, never the child.
@immutable
class GlassStyle {
  const GlassStyle({
    this.blurSigmaX = 12,
    this.blurSigmaY = 12,
    this.blurEnabled = true,
    this.tintColor = Colors.white,
    this.tintOpacity = 0.16,
    this.backgroundGradient = null,
    this.saturation = 1,
    this.contrast = 1,
    this.borderColor = Colors.white,
    this.borderOpacity = 0.38,
    this.borderWidth = 1,
    this.borderGradient = null,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.shape = BoxShape.rectangle,
    this.highlightColor = Colors.white,
    this.highlightOpacity = 0.18,
    this.highlightAngle = -0.8,
    this.shadowColor = Colors.black,
    this.shadowOpacity = 0.10,
    this.shadowBlurRadius = 20,
    this.shadowOffset = const Offset(0, 8),
    this.noiseOpacity = 0.025,
    this.noiseEnabled = false,
  }) : assert(
         blurSigmaX >= 0 &&
             blurSigmaY >= 0 &&
             blurSigmaX < double.infinity &&
             blurSigmaY < double.infinity,
       ),
       assert(tintOpacity >= 0 && tintOpacity <= 1),
       assert(borderOpacity >= 0 && borderOpacity <= 1),
       assert(highlightOpacity >= 0 && highlightOpacity <= 1),
       assert(shadowOpacity >= 0 && shadowOpacity <= 1),
       assert(noiseOpacity >= 0 && noiseOpacity <= 1),
       assert(
         borderWidth >= 0 &&
             shadowBlurRadius >= 0 &&
             borderWidth < double.infinity &&
             shadowBlurRadius < double.infinity,
       ),
       assert(
         saturation >= 0 &&
             contrast >= 0 &&
             saturation < double.infinity &&
             contrast < double.infinity,
       ),
       assert(
         highlightAngle > double.negativeInfinity &&
             highlightAngle < double.infinity,
       );

  final double blurSigmaX;
  final double blurSigmaY;
  final bool blurEnabled;
  final Color tintColor;
  final double tintOpacity;
  final Gradient? backgroundGradient;
  final double saturation;
  final double contrast;
  final Color borderColor;
  final double borderOpacity;
  final double borderWidth;
  final Gradient? borderGradient;
  final BorderRadius borderRadius;
  final BoxShape shape;
  final Color highlightColor;
  final double highlightOpacity;
  final double highlightAngle;
  final Color shadowColor;
  final double shadowOpacity;
  final double shadowBlurRadius;
  final Offset shadowOffset;
  final double noiseOpacity;
  final bool noiseEnabled;

  /// Nullable gradients can be explicitly cleared with null.
  GlassStyle copyWith({
    double? blurSigmaX,
    double? blurSigmaY,
    bool? blurEnabled,
    Color? tintColor,
    double? tintOpacity,
    Object? backgroundGradient = _unset,
    double? saturation,
    double? contrast,
    Color? borderColor,
    double? borderOpacity,
    double? borderWidth,
    Object? borderGradient = _unset,
    BorderRadius? borderRadius,
    BoxShape? shape,
    Color? highlightColor,
    double? highlightOpacity,
    double? highlightAngle,
    Color? shadowColor,
    double? shadowOpacity,
    double? shadowBlurRadius,
    Offset? shadowOffset,
    double? noiseOpacity,
    bool? noiseEnabled,
  }) => GlassStyle(
    blurSigmaX: blurSigmaX ?? this.blurSigmaX,
    blurSigmaY: blurSigmaY ?? this.blurSigmaY,
    blurEnabled: blurEnabled ?? this.blurEnabled,
    tintColor: tintColor ?? this.tintColor,
    tintOpacity: tintOpacity ?? this.tintOpacity,
    backgroundGradient: identical(backgroundGradient, _unset)
        ? this.backgroundGradient
        : backgroundGradient as Gradient?,
    saturation: saturation ?? this.saturation,
    contrast: contrast ?? this.contrast,
    borderColor: borderColor ?? this.borderColor,
    borderOpacity: borderOpacity ?? this.borderOpacity,
    borderWidth: borderWidth ?? this.borderWidth,
    borderGradient: identical(borderGradient, _unset)
        ? this.borderGradient
        : borderGradient as Gradient?,
    borderRadius: borderRadius ?? this.borderRadius,
    shape: shape ?? this.shape,
    highlightColor: highlightColor ?? this.highlightColor,
    highlightOpacity: highlightOpacity ?? this.highlightOpacity,
    highlightAngle: highlightAngle ?? this.highlightAngle,
    shadowColor: shadowColor ?? this.shadowColor,
    shadowOpacity: shadowOpacity ?? this.shadowOpacity,
    shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
    shadowOffset: shadowOffset ?? this.shadowOffset,
    noiseOpacity: noiseOpacity ?? this.noiseOpacity,
    noiseEnabled: noiseEnabled ?? this.noiseEnabled,
  );

  /// Numeric/color fields interpolate; discrete fields switch at halfway.
  static GlassStyle lerp(GlassStyle a, GlassStyle b, double t) {
    t = t.clamp(0.0, 1.0);
    if (t == 0) return a;
    if (t == 1) return b;
    return GlassStyle(
      blurSigmaX: ui.lerpDouble(a.blurSigmaX, b.blurSigmaX, t)!,
      blurSigmaY: ui.lerpDouble(a.blurSigmaY, b.blurSigmaY, t)!,
      blurEnabled: t < 0.5 ? a.blurEnabled : b.blurEnabled,
      tintColor: Color.lerp(a.tintColor, b.tintColor, t)!,
      tintOpacity: ui.lerpDouble(a.tintOpacity, b.tintOpacity, t)!,
      backgroundGradient: Gradient.lerp(
        a.backgroundGradient,
        b.backgroundGradient,
        t,
      ),
      saturation: ui.lerpDouble(a.saturation, b.saturation, t)!,
      contrast: ui.lerpDouble(a.contrast, b.contrast, t)!,
      borderColor: Color.lerp(a.borderColor, b.borderColor, t)!,
      borderOpacity: ui.lerpDouble(a.borderOpacity, b.borderOpacity, t)!,
      borderWidth: ui.lerpDouble(a.borderWidth, b.borderWidth, t)!,
      borderGradient: Gradient.lerp(a.borderGradient, b.borderGradient, t),
      borderRadius: BorderRadius.lerp(a.borderRadius, b.borderRadius, t)!,
      shape: t < 0.5 ? a.shape : b.shape,
      highlightColor: Color.lerp(a.highlightColor, b.highlightColor, t)!,
      highlightOpacity: ui.lerpDouble(
        a.highlightOpacity,
        b.highlightOpacity,
        t,
      )!,
      highlightAngle: ui.lerpDouble(a.highlightAngle, b.highlightAngle, t)!,
      shadowColor: Color.lerp(a.shadowColor, b.shadowColor, t)!,
      shadowOpacity: ui.lerpDouble(a.shadowOpacity, b.shadowOpacity, t)!,
      shadowBlurRadius: ui.lerpDouble(
        a.shadowBlurRadius,
        b.shadowBlurRadius,
        t,
      )!,
      shadowOffset: Offset.lerp(a.shadowOffset, b.shadowOffset, t)!,
      noiseOpacity: ui.lerpDouble(a.noiseOpacity, b.noiseOpacity, t)!,
      noiseEnabled: t < 0.5 ? a.noiseEnabled : b.noiseEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GlassStyle &&
          blurSigmaX == other.blurSigmaX &&
          blurSigmaY == other.blurSigmaY &&
          blurEnabled == other.blurEnabled &&
          tintColor == other.tintColor &&
          tintOpacity == other.tintOpacity &&
          backgroundGradient == other.backgroundGradient &&
          saturation == other.saturation &&
          contrast == other.contrast &&
          borderColor == other.borderColor &&
          borderOpacity == other.borderOpacity &&
          borderWidth == other.borderWidth &&
          borderGradient == other.borderGradient &&
          borderRadius == other.borderRadius &&
          shape == other.shape &&
          highlightColor == other.highlightColor &&
          highlightOpacity == other.highlightOpacity &&
          highlightAngle == other.highlightAngle &&
          shadowColor == other.shadowColor &&
          shadowOpacity == other.shadowOpacity &&
          shadowBlurRadius == other.shadowBlurRadius &&
          shadowOffset == other.shadowOffset &&
          noiseOpacity == other.noiseOpacity &&
          noiseEnabled == other.noiseEnabled;
  @override
  int get hashCode => Object.hashAll([
    blurSigmaX,
    blurSigmaY,
    blurEnabled,
    tintColor,
    tintOpacity,
    backgroundGradient,
    saturation,
    contrast,
    borderColor,
    borderOpacity,
    borderWidth,
    borderGradient,
    borderRadius,
    shape,
    highlightColor,
    highlightOpacity,
    highlightAngle,
    shadowColor,
    shadowOpacity,
    shadowBlurRadius,
    shadowOffset,
    noiseOpacity,
    noiseEnabled,
  ]);
}

/// Starting points; use copyWith to personalize without subclassing.
abstract final class GlassPresets {
  static const subtle = GlassStyle(
    blurSigmaX: 6,
    blurSigmaY: 6,
    tintOpacity: .08,
    shadowOpacity: 0,
  );
  static const card = GlassStyle();
  static const elevatedCard = GlassStyle(
    blurSigmaX: 18,
    blurSigmaY: 18,
    tintOpacity: .22,
    shadowOpacity: .16,
  );
  static const button = GlassStyle(
    blurSigmaX: 8,
    blurSigmaY: 8,
    tintOpacity: .24,
    borderRadius: BorderRadius.all(Radius.circular(16)),
    shadowOpacity: .04,
  );
  static const appBar = GlassStyle(
    blurSigmaX: 10,
    blurSigmaY: 10,
    tintOpacity: .3,
    borderRadius: BorderRadius.zero,
    shadowOpacity: 0,
  );
  static const dialog = GlassStyle(
    blurSigmaX: 20,
    blurSigmaY: 20,
    tintOpacity: .85,
    shadowOpacity: .2,
  );
  static const selected = GlassStyle(
    tintColor: Color(0xff457bea),
    tintOpacity: .35,
    borderOpacity: .65,
  );
}
