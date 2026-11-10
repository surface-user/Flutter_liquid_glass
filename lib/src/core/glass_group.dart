import 'package:flutter/material.dart';

/// Share only among non-overlapping surfaces. Set overlapping to true for
/// stacks, nested surfaces, or any layout whose painted bounds can intersect.
class GlassGroup extends InheritedWidget {
  GlassGroup({super.key, this.overlapping = false, required Widget child})
    : super(child: BackdropGroup(child: child));
  final bool overlapping;
  @override
  bool updateShouldNotify(GlassGroup oldWidget) =>
      overlapping != oldWidget.overlapping;
}
