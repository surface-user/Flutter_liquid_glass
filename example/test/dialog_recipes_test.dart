import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass_example/recipes/dialog_recipes.dart';

void main() {
  testWidgets('information has a route title and scrolls in a narrow window', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 420);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const DialogRecipesDemo());
    await tester.tap(find.text('查看说明'));
    await tester.pumpAndSettle();

    final dialog = find.byType(AlertDialog);
    expect(find.text('关于标题'), findsOneWidget);
    expect(
      find.descendant(
        of: dialog,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.namesRoute == true &&
              widget.properties.label == '关于标题',
        ),
      ),
      findsOneWidget,
    );
    final route = ModalRoute.of(tester.element(dialog))!;
    expect(route.transitionDuration, Duration.zero);
    expect(route.reverseTransitionDuration, Duration.zero);
    final scroll = find.descendant(
      of: dialog,
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scroll).position;
    expect(position.maxScrollExtent, greaterThan(0));
    await tester.drag(scroll, const Offset(0, -160));
    await tester.pumpAndSettle();
    expect(position.pixels, greaterThan(0));
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(dialog, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'editing validates, returns the title, and discards other exits',
    (tester) async {
      await tester.pumpWidget(const DialogRecipesDemo());
      final trigger = find.text('修改标题');
      final input = find.byType(TextFormField);
      final editable = find.byType(EditableText);
      await tester.tap(trigger);
      await tester.pumpAndSettle();
      expect(tester.widget<EditableText>(editable).controller.text, '示例标题');

      await tester.enterText(input, '   ');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('请输入标题'), findsOneWidget);
      await tester.enterText(input, '  新标题  ');
      final cancel = tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Cancel'))
          .onPressed!;
      await tester.testTextInput.receiveAction(TextInputAction.done);
      cancel();
      await tester.pumpAndSettle();
      expect(input, findsNothing);
      expect(find.text('当前标题：新标题'), findsOneWidget);
      expect(find.text('结果：已修改'), findsOneWidget);

      await tester.tap(trigger);
      await tester.pumpAndSettle();
      expect(tester.widget<EditableText>(editable).controller.text, '新标题');
      await tester.enterText(input, '取消的修改');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('当前标题：新标题'), findsOneWidget);
      expect(find.text('结果：取消'), findsOneWidget);

      await tester.tap(trigger);
      await tester.pumpAndSettle();
      await tester.enterText(input, '关闭时的修改');
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();
      expect(input, findsNothing);
      expect(find.text('当前标题：新标题'), findsOneWidget);
      expect(find.text('结果：无值关闭'), findsOneWidget);
    },
  );

  testWidgets(
    'keyboard opens the editor, loops focus and restores the trigger',
    (tester) async {
      await tester.pumpWidget(const DialogRecipesDemo());
      await tester.pumpAndSettle();
      final triggerFocus = FocusManager.instance.primaryFocus!;
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      final editable = find.byType(EditableText);
      final fieldFocus = tester.widget<EditableText>(editable).focusNode;
      expect(fieldFocus.hasPrimaryFocus, isTrue);
      for (var index = 0; index < 3; index++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(triggerFocus.hasFocus, isFalse);
        expect(fieldFocus.hasPrimaryFocus, index == 2);
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(editable, findsNothing);
      expect(find.text('结果：无值关闭'), findsOneWidget);
      expect(triggerFocus.hasPrimaryFocus, isTrue);
    },
  );
}
