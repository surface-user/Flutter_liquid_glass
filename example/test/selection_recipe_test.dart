import 'dart:ui' show CheckedState, SemanticsFlags;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass_example/recipes/selection_recipe.dart';

void main() {
  const checkbox = '显示详细信息';
  const gate = '允许修改选项';
  const comfortable = '宽松布局';
  const unavailable = '不可用的布局';
  const compact = '紧凑布局';
  const preview = '显示预览';

  SemanticsFlags flags(String label) => find.semantics
      .byLabel(label)
      .evaluate()
      .single
      .getSemanticsData()
      .flagsCollection;

  testWidgets('checkbox cycles through unchecked, checked and mixed', (
    tester,
  ) async {
    await tester.pumpWidget(const SelectionRecipeDemo());
    CheckedState check() => flags(checkbox).isChecked;
    expect(check(), CheckedState.isFalse);
    for (final state in [
      CheckedState.isTrue,
      CheckedState.mixed,
      CheckedState.isFalse,
    ]) {
      await tester.tap(find.text(checkbox));
      await tester.pumpAndSettle();
      expect(check(), state);
    }
  });

  testWidgets('radio keys change one choice and skip the disabled choice', (
    tester,
  ) async {
    await tester.pumpWidget(const SelectionRecipeDemo());
    CheckedState check(String label) => flags(label).isChecked;
    expect(check(comfortable), CheckedState.isTrue);
    expect(check(compact), CheckedState.isFalse);
    expect(flags(comfortable).isInMutuallyExclusiveGroup, isTrue);
    for (var index = 0; index < 3; index++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
    }
    expect(flags(comfortable).isFocused.toBoolOrNull(), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(check(comfortable), CheckedState.isFalse);
    expect(check(compact), CheckedState.isTrue);
    expect(check(unavailable), CheckedState.isFalse);
    expect(flags(compact).isFocused.toBoolOrNull(), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(check(comfortable), CheckedState.isTrue);
    expect(check(compact), CheckedState.isFalse);
  });

  testWidgets('disabled choices retain values in a narrow 2x layout', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(280, 640);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const SelectionRecipeDemo());

    Future<void> tap(String label, {double scroll = 96}) async {
      final target = find.text(label);
      await tester.scrollUntilVisible(target, scroll);
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    await tap(checkbox);
    await tap(compact);
    await tap(preview);
    expect(flags(preview).isToggled.toBoolOrNull(), isTrue);
    await tap(gate, scroll: -96);
    await tap(checkbox);
    expect(flags(checkbox).isEnabled.toBoolOrNull(), isFalse);
    expect(flags(checkbox).isChecked, CheckedState.isTrue);
    await tap(comfortable);
    expect(flags(comfortable).isEnabled.toBoolOrNull(), isFalse);
    expect(flags(comfortable).isChecked, CheckedState.isFalse);
    await tap(compact);
    expect(flags(compact).isEnabled.toBoolOrNull(), isFalse);
    expect(flags(compact).isChecked, CheckedState.isTrue);
    await tap(preview);
    expect(flags(preview).isEnabled.toBoolOrNull(), isFalse);
    expect(flags(preview).isToggled.toBoolOrNull(), isTrue);
    expect(tester.takeException(), isNull);
  });
}
