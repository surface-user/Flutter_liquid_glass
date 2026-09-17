import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

void main() {
  test(
    'style interpolation preserves endpoints and interpolates appearance',
    () {
      const a = GlassStyle(blurSigmaX: 0, tintOpacity: .1, borderWidth: 0);
      final b = a.copyWith(
        blurSigmaX: 20,
        tintOpacity: .9,
        borderWidth: 2,
        borderRadius: BorderRadius.circular(40),
        tintColor: Colors.blue,
      );
      expect(GlassStyle.lerp(a, b, 0), same(a));
      expect(GlassStyle.lerp(a, b, 1), same(b));
      final mid = GlassStyle.lerp(a, b, .5);
      expect(mid.blurSigmaX, 10);
      expect(mid.tintOpacity, .5);
      expect(mid.borderWidth, 1);
      expect(mid.borderRadius.topLeft.x, 32);
      expect(mid.tintColor, Color.lerp(a.tintColor, b.tintColor, .5));
      expect(GlassStyle.lerp(a, b, 2), same(b));
      expect(a.copyWith(), a);
      expect(a.copyWith().hashCode, a.hashCode);
    },
  );
  test('copyWith can clear nullable gradients', () {
    const gradient = LinearGradient(colors: [Colors.red, Colors.blue]);
    const style = GlassStyle(
      backgroundGradient: gradient,
      borderGradient: gradient,
    );
    expect(style.copyWith().backgroundGradient, gradient);
    expect(
      style
          .copyWith(backgroundGradient: null, borderGradient: null)
          .backgroundGradient,
      isNull,
    );
    expect(style.copyWith(borderGradient: null).borderGradient, isNull);
  });
  test('invalid values fail early and low quality has zero blur budget', () {
    expect(() => GlassStyle(blurSigmaX: -1), throwsAssertionError);
    expect(() => GlassStyle(tintOpacity: 2), throwsAssertionError);
    expect(
      const GlassPerformanceConfig(
        quality: GlassQuality.low,
      ).effectiveMaxBlurSigma,
      0,
    );
    expect(
      const GlassPerformanceConfig(maxBlurSigma: 50).effectiveMaxBlurSigma,
      16,
    );
  });
  test('theme lerps surface presets and preserves configuration', () {
    const a = LiquidGlassThemeData();
    final b = LiquidGlassThemeData.dark();
    final mid = a.lerp(b, .5);
    expect(mid.cardStyle, GlassStyle.lerp(a.cardStyle, b.cardStyle, .5));
    expect(mid.brightness, Brightness.dark);
    expect(a.copyWith(accentColor: Colors.red).accentColor, Colors.red);
  });
}
