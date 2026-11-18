import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass_example/recipes/anchored_menu_recipe.dart';

void main() {
  final trigger = find.widgetWithText(FilledButton, '打开菜单');
  final view = find.widgetWithText(MenuItemButton, '查看');
  final refresh = find.widgetWithText(MenuItemButton, '刷新');
  final disabled = find.widgetWithText(MenuItemButton, '不可用命令');

  testWidgets('Enter opens and activates; arrows skip the disabled item', (
    tester,
  ) async {
    await tester.pumpWidget(const AnchoredMenuRecipeDemo());
    await tester.pumpAndSettle();
    final triggerFocus = tester.widget<FilledButton>(trigger).focusNode!;
    expect(triggerFocus.hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    final firstFocus = tester.widget<MenuItemButton>(view).focusNode!;
    expect(firstFocus.hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(
      find.semantics
          .byLabel('刷新')
          .evaluate()
          .single
          .getSemanticsData()
          .flagsCollection
          .isFocused
          .toBoolOrNull(),
      isTrue,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(firstFocus.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(refresh, findsNothing);
    expect(find.text('命令：刷新（1 次）'), findsOneWidget);
    expect(triggerFocus.hasPrimaryFocus, isTrue);
  });

  testWidgets('disabled item and Escape do not execute a command', (
    tester,
  ) async {
    await tester.pumpWidget(const AnchoredMenuRecipeDemo());
    await tester.tap(trigger);
    await tester.pumpAndSettle();
    expect(
      find.semantics
          .byLabel('不可用命令')
          .evaluate()
          .single
          .getSemanticsData()
          .flagsCollection
          .isEnabled
          .toBoolOrNull(),
      isFalse,
    );
    await tester.tap(disabled);
    await tester.pumpAndSettle();
    expect(disabled, findsOneWidget);
    expect(find.text('命令：无（0 次）'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(disabled, findsNothing);
    expect(find.text('命令：无（0 次）'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(trigger).focusNode!.hasPrimaryFocus,
      isTrue,
    );
  });

  testWidgets('outside tap closes without reaching the button behind it', (
    tester,
  ) async {
    await tester.pumpWidget(const AnchoredMenuRecipeDemo());
    final outside = find.widgetWithText(TextButton, '菜单外按钮：0');
    await tester.tap(trigger);
    await tester.pumpAndSettle();
    expect(view, findsOneWidget);

    await tester.tap(outside);
    await tester.pumpAndSettle();
    expect(view, findsNothing);
    expect(outside, findsOneWidget);
    expect(find.text('命令：无（0 次）'), findsOneWidget);

    await tester.tap(outside);
    await tester.pumpAndSettle();
    expect(find.text('菜单外按钮：1'), findsOneWidget);
  });

  testWidgets('edge-anchored menu stays reachable in a narrow viewport', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(280, 360);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const AnchoredMenuRecipeDemo());
    await tester.tap(trigger);
    await tester.pump();
    expect(refresh.hitTestable(), findsOneWidget);
    final bounds = tester.getRect(refresh);
    expect(bounds.left, greaterThanOrEqualTo(0));
    expect(bounds.right, lessThanOrEqualTo(280));
    expect(bounds.top, greaterThanOrEqualTo(0));
    expect(bounds.bottom, lessThanOrEqualTo(360));
    expect(bounds.bottom, lessThanOrEqualTo(tester.getTopLeft(trigger).dy));

    await tester.tap(refresh);
    await tester.pumpAndSettle();
    expect(find.text('命令：刷新（1 次）'), findsOneWidget);
    expect(refresh, findsNothing);
    expect(tester.takeException(), isNull);
  });
}
