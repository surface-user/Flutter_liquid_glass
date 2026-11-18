import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsAction;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

void main() {
  for (final surface in ['solid', 'glass', 'glass without blur']) {
    testWidgets('navigation selection, focus and activation on $surface', (
      tester,
    ) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      var activations = 0;

      Future<void> showItem({bool selected = false, bool disabled = false}) =>
          tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(
                extensions: [
                  LiquidGlassThemeData(
                    performance: GlassPerformanceConfig(
                      blurEnabled: surface == 'glass',
                    ),
                  ),
                ],
              ),
              home: Scaffold(
                body: Center(
                  child: Builder(
                    builder: (context) {
                      final item = NavigationItem(
                        label: 'Projects',
                        selected: selected,
                        focusNode: focusNode,
                        onPressed: disabled ? null : () => activations++,
                      );
                      return SizedBox(
                        width: 240,
                        child: surface == 'solid'
                            ? Material(
                                color: Theme.of(context).colorScheme.surface,
                                child: item,
                              )
                            : GlassSurface(child: item),
                      );
                    },
                  ),
                ),
              ),
            ),
          );

      final label = find.text('Projects');
      bool isSelected() =>
          tester
              .getSemantics(label)
              .flagsCollection
              .isSelected
              .toBoolOrNull() ==
          true;

      await showItem();
      await tester.pumpAndSettle();
      expect(
        find.byType(BackdropFilter),
        surface == 'glass' ? findsOneWidget : findsNothing,
      );
      expect(isSelected(), isFalse);
      expect(tester.getSemantics(label).label, 'Projects');
      expect(tester.getSemantics(label).flagsCollection.isButton, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isTrue);
      expect(isSelected(), isFalse);
      expect(activations, 0);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(activations, 1);
      expect(isSelected(), isFalse);

      await showItem(selected: true);
      await tester.pumpAndSettle();
      expect(isSelected(), isTrue);
      expect(focusNode.hasFocus, isTrue);
      expect(
        tester.getSemantics(label).flagsCollection.isFocused.toBoolOrNull(),
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(activations, 2);
      await tester.tap(label);
      await tester.pumpAndSettle();
      expect(activations, 3);
      expect(isSelected(), isTrue);

      await showItem(selected: true, disabled: true);
      await tester.pumpAndSettle();
      expect(isSelected(), isTrue);
      expect(
        tester
            .getSemantics(label)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isFalse,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.tap(label);
      await tester.pumpAndSettle();
      expect(activations, 3);

      await tester.pumpWidget(const SizedBox());
      await showItem();
      focusNode.requestFocus();
      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isTrue);
    });
  }

  testWidgets('label and slots fit a narrow RTL row at 2x text size', (
    tester,
  ) async {
    const label = '很长的项目导航标题，用来验证文字截断';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Center(
                child: SizedBox(
                  width: 160,
                  child: NavigationItem(
                    label: label,
                    leading: const Icon(Icons.folder_outlined),
                    trailing: const Icon(Icons.chevron_left),
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final text = find.text(label);
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(NavigationItem)).height,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.getCenter(find.byIcon(Icons.folder_outlined)).dx,
      greaterThan(tester.getCenter(text).dx),
    );
    expect(
      tester.getCenter(find.byIcon(Icons.chevron_left)).dx,
      lessThan(tester.getCenter(text).dx),
    );
    expect(find.byTooltip(label), findsOneWidget);
  });
}
