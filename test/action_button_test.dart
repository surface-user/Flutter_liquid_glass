import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsAction;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

void main() {
  testWidgets(
    'both action entries request activation once; disabled and cancel do not',
    (tester) async {
      for (final icon in [false, true]) {
        final focus = FocusNode();
        addTearDown(focus.dispose);
        var calls = 0;
        final entry = find.byType(icon ? IconActionButton : ActionButton);
        const label = '保存';

        Future<void> show(VoidCallback? callback) => tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: icon
                    ? IconActionButton(
                        icon: const Icon(
                          Icons.save,
                          semanticLabel: 'decorative',
                        ),
                        tooltip: label,
                        onPressed: callback,
                        focusNode: focus,
                      )
                    : ActionButton(
                        child: const Text(label),
                        onPressed: callback,
                        focusNode: focus,
                      ),
              ),
            ),
          ),
        );

        await show(() => calls++);
        focus.requestFocus();
        await tester.pumpAndSettle();
        await tester.tap(entry);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        final node = tester.getSemantics(find.bySemanticsLabel(label));
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
        node.owner!.performAction(node.id, SemanticsAction.tap);
        expect(calls, 4);
        expect(find.bySemanticsLabel('decorative'), findsNothing);

        final gesture = await tester.startGesture(tester.getCenter(entry));
        await gesture.moveBy(const Offset(160, 0));
        await gesture.up();
        expect(calls, 4);

        await show(null);
        await tester.pumpAndSettle();
        final disabledNode = tester.getSemantics(find.bySemanticsLabel(label));
        expect(
          disabledNode.getSemanticsData().hasAction(SemanticsAction.tap),
          isFalse,
        );
        await tester.tap(entry);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        expect(calls, 4);
      }
    },
  );

  testWidgets(
    'loading blocks all activation and keeps focus, name and geometry',
    (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      var calls = 0;
      const label = '保存当前工作区';
      final entry = find.byType(ActionButton);
      final labelNode = find.bySemanticsLabel(label);

      Future<void> show(bool loading, {required bool disabledMotion}) =>
          tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(disableAnimations: disabledMotion),
                  child: Scaffold(
                    body: Center(
                      child: GlassSurface(
                        child: ActionButton(
                          leading: const Icon(Icons.save),
                          onPressed: () => calls++,
                          focusNode: focus,
                          loading: loading,
                          child: const Text(label),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );

      await show(false, disabledMotion: false);
      focus.requestFocus();
      await tester.pumpAndSettle();
      final original = tester.getRect(entry);
      expect(original.width, greaterThanOrEqualTo(48));
      expect(original.height, greaterThanOrEqualTo(48));
      await tester.tap(entry);
      expect(calls, 1);

      await show(true, disabledMotion: true);
      await tester.pumpAndSettle();
      expect(focus.hasFocus, isTrue);
      expect(tester.getRect(entry), original);
      final busyNode = tester.getSemantics(labelNode);
      expect(
        busyNode.getSemanticsData().hasAction(SemanticsAction.tap),
        isFalse,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.role == SemanticsRole.loadingSpinner,
        ),
        findsOneWidget,
      );
      busyNode.owner!.performAction(busyNode.id, SemanticsAction.tap);
      final heldWhileBusy = await tester.startGesture(tester.getCenter(entry));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(tester.binding.hasScheduledFrame, isFalse);

      await show(false, disabledMotion: true);
      await tester.pumpAndSettle();
      await heldWhileBusy.up();
      expect(calls, 1);
      expect(focus.hasFocus, isTrue);
      expect(tester.getRect(entry), original);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(calls, 2);
      await tester.pumpWidget(const SizedBox());
      focus.requestFocus();
    },
  );

  testWidgets('action styling resolves by field and scope on the same button', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    const globalFocus = Color(0xFF215C94);
    const globalRadius = BorderRadius.all(Radius.circular(27));
    const localRadius = BorderRadius.all(Radius.circular(14));
    const localPrimaryRadius = BorderRadius.all(Radius.circular(21));
    const instanceRadius = BorderRadius.zero;
    const global = ActionButtonThemeData(
      primary: ActionButtonStyle(
        borderRadius: globalRadius,
        focusBorderColor: globalFocus,
      ),
    );
    const local = ActionButtonThemeData(
      style: ActionButtonStyle(borderRadius: localRadius),
      primary: ActionButtonStyle(borderRadius: localPrimaryRadius),
    );

    Future<void> show({
      required ActionButtonThemeData data,
      ActionButtonStyle? style,
      bool highContrast = false,
    }) => tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [global]),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(highContrast: highContrast),
            child: Scaffold(
              body: Center(
                child: ActionButtonTheme(
                  data: data,
                  child: ActionButton(
                    onPressed: () {},
                    focusNode: focus,
                    variant: ActionButtonVariant.primary,
                    style: style,
                    child: const Text('应用'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    RoundedRectangleBorder shape() =>
        tester
                .widget<Material>(
                  find.descendant(
                    of: find.byType(ActionButton),
                    matching: find.byType(Material),
                  ),
                )
                .shape!
            as RoundedRectangleBorder;

    await show(data: const ActionButtonThemeData());
    focus.requestFocus();
    await tester.pumpAndSettle();
    expect(shape().borderRadius, globalRadius);
    expect(shape().side.color, globalFocus);

    await show(
      data: const ActionButtonThemeData(
        style: ActionButtonStyle(borderRadius: localRadius),
      ),
    );
    expect(shape().borderRadius, localRadius);
    expect(shape().side.color, globalFocus);

    await show(data: local);
    expect(shape().borderRadius, localPrimaryRadius);
    expect(shape().side.color, globalFocus);

    await show(
      data: local,
      style: const ActionButtonStyle(borderRadius: instanceRadius),
      highContrast: true,
    );
    expect(shape().borderRadius, instanceRadius);
    expect(shape().side.color, ThemeData().colorScheme.onPrimary);
    expect(focus.hasFocus, isTrue);
  });
}
