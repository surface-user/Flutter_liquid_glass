import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsAction;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

void main() {
  testWidgets(
    'tab activation and closure have independent keyboard and semantics',
    (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      var openings = 0;
      var closings = 0;
      const label = '项目';
      const closeLabel = '关闭项目';
      final tabFinder = find.bySemanticsLabel(label);
      final closeFinder = find.bySemanticsLabel(closeLabel);

      Future<void> show({bool selected = false}) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NavigationTab(
                label: label,
                selected: selected,
                onPressed: () => openings++,
                onClose: () => closings++,
                closeTooltip: closeLabel,
                focusNode: focus,
              ),
            ),
          ),
        ),
      );

      await show();
      focus.requestFocus();
      await tester.pumpAndSettle();
      final tab = tester.getSemantics(tabFinder);
      final close = tester.getSemantics(closeFinder);
      expect(tab.getSemanticsData().role, SemanticsRole.tab);
      expect(tab.flagsCollection.isSelected.toBoolOrNull(), isFalse);
      expect(tab.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      expect(close.flagsCollection.isButton, isTrue);
      expect(close.flagsCollection.isSelected.toBoolOrNull(), isNull);
      expect(close.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      expect(tab.id, isNot(close.id));

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.tap(find.text(label));
      expect(openings, 2);
      expect(closings, 0);
      expect(
        tester
            .getSemantics(tabFinder)
            .flagsCollection
            .isSelected
            .toBoolOrNull(),
        isFalse,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(focus.hasFocus, isFalse);
      expect(
        tester
            .getSemantics(closeFinder)
            .flagsCollection
            .isFocused
            .toBoolOrNull(),
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      final closeButton = find.byType(IconActionButton).hitTestable();
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      expect(openings, 2);
      expect(closings, 2);
      expect(tabFinder, findsOneWidget);
      expect(
        tester
            .getSemantics(tabFinder)
            .flagsCollection
            .isSelected
            .toBoolOrNull(),
        isFalse,
      );

      await show(selected: true);
      expect(
        tester
            .getSemantics(tabFinder)
            .flagsCollection
            .isSelected
            .toBoolOrNull(),
        isTrue,
      );
    },
  );

  testWidgets(
    'disabled selection leaves close available; null close hides it',
    (tester) async {
      var closings = 0;
      const label = '只读项目';
      const closeLabel = '关闭只读项目';

      Future<void> show({required bool closable}) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationTab(
              label: label,
              selected: true,
              onClose: closable ? () => closings++ : null,
              closeTooltip: closable ? closeLabel : null,
            ),
          ),
        ),
      );

      await show(closable: true);
      final tab = tester.getSemantics(find.bySemanticsLabel(label));
      expect(tab.getSemanticsData().role, SemanticsRole.tab);
      expect(tab.flagsCollection.isSelected.toBoolOrNull(), isTrue);
      expect(tab.flagsCollection.isEnabled.toBoolOrNull(), isFalse);
      expect(tab.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      await tester.tap(find.text(label));
      expect(closings, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final close = tester.getSemantics(find.bySemanticsLabel(closeLabel));
      expect(close.flagsCollection.isFocused.toBoolOrNull(), isTrue);
      close.owner!.performAction(close.id, SemanticsAction.tap);
      expect(closings, 1);

      await show(closable: false);
      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.bySemanticsLabel(closeLabel), findsNothing);
      expect(find.bySemanticsLabel(label), findsOneWidget);
    },
  );

  for (final glass in [false, true]) {
    testWidgets(
      'narrow RTL tab keeps full labels and targets on glass=$glass',
      (tester) async {
        const label = '一个在窄栏中需要省略的工作区项目标题';
        const closeLabel = '关闭该工作区项目';
        var openings = 0;
        var closings = 0;
        final tab = NavigationTab(
          label: label,
          selected: true,
          onPressed: () => openings++,
          onClose: () => closings++,
          closeTooltip: closeLabel,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(2)),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Center(
                      child: SizedBox(
                        width: 120,
                        child: glass
                            ? GlassSurface(child: tab)
                            : Material(child: tab),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        final text = find.text(label);
        final close = find.byIcon(Icons.close);
        final primary = find.ancestor(
          of: text,
          matching: find.byType(TextButton),
        );
        final closeButton = find.byType(IconActionButton).hitTestable();
        expect(tester.getCenter(close).dx, lessThan(tester.getCenter(text).dx));
        expect(find.bySemanticsLabel(label), findsOneWidget);
        expect(find.bySemanticsLabel(closeLabel), findsOneWidget);
        expect(closeButton, findsOneWidget);
        expect(tester.getSize(primary).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(closeButton).width, greaterThanOrEqualTo(48));

        await tester.tap(text);
        await tester.tap(closeButton);
        expect(openings, 1);
        expect(closings, 1);
      },
    );
  }
}
