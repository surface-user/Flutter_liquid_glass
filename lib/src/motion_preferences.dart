import 'package:flutter/widgets.dart';

bool get platformRequestsReducedMotion => WidgetsBinding
    .instance
    .platformDispatcher
    .accessibilityFeatures
    .reduceMotion;

class PlatformReduceMotionObserver with WidgetsBindingObserver {
  PlatformReduceMotionObserver(this.onChanged);

  final ValueChanged<bool> onChanged;
  bool? _lastValue;

  set listening(bool value) {
    if (value == (_lastValue != null)) return;
    if (value) {
      _lastValue = platformRequestsReducedMotion;
      WidgetsBinding.instance.addObserver(this);
    } else {
      WidgetsBinding.instance.removeObserver(this);
      _lastValue = null;
    }
  }

  @override
  void didChangeAccessibilityFeatures() {
    final value = platformRequestsReducedMotion;
    if (_lastValue == null || _lastValue == value) return;
    _lastValue = value;
    onChanged(value);
  }
}
