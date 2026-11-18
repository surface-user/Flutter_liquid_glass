import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass_example/recipes/workbench_recipe.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

Finder _tab(String view) => find.byKey(ValueKey('tab-$view'));
Finder _navigation(String view) => find.byKey(ValueKey('nav-$view'));

void main() {
  testWidgets('sidebar and tabs share selection and close independently', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WorkbenchRecipe()));
    await tester.tap(_navigation('project'));
    await tester.pumpAndSettle();
    expect(find.text('Project summary'), findsOneWidget);
    expect(tester.widget<NavigationTab>(_tab('project')).selected, isTrue);

    await tester.tap(find.byTooltip('Close Activity'));
    await tester.pumpAndSettle();
    expect(_tab('activity'), findsNothing);
    expect(find.text('Project summary'), findsOneWidget);

    await tester.tap(_tab('overview'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationItem>(_navigation('overview')).selected,
      isTrue,
    );
    await tester.tap(_navigation('activity'));
    await tester.pumpAndSettle();
    expect(find.text('Recent activity'), findsOneWidget);
    expect(tester.widget<NavigationTab>(_tab('activity')).selected, isTrue);
    await tester.tap(find.byTooltip('Close Activity'));
    await tester.pumpAndSettle();
    expect(find.text('Workspace summary'), findsOneWidget);
    expect(tester.widget<NavigationTab>(_tab('overview')).selected, isTrue);
  });

  testWidgets('surface switches retain the draft and bound glass filtering', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WorkbenchRecipe()));
    final field = find.byType(TextField);
    final filter = find.byType(BackdropFilter);
    expect(filter, findsNothing);
    const draft = 'An unsaved draft\nSecond line';
    await tester.enterText(field, draft);
    await tester.pumpAndSettle();

    for (final (label, glass, filters) in [
      ('Glass', true, 1),
      ('No blur', true, 0),
      ('Solid', false, 0),
    ]) {
      await tester.tap(find.widgetWithText(ChoiceChip, label));
      await tester.pumpAndSettle();
      expect(find.byType(GlassSurface), glass ? findsOneWidget : findsNothing);
      expect(filter, findsNWidgets(filters));
      expect(find.text('Workspace summary'), findsOneWidget);
      expect(tester.widget<TextField>(field).controller!.text, draft);
    }
  });

  testWidgets(
    'only confirmation applies the draft and returns keyboard focus',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: WorkbenchRecipe()));
      await tester.enterText(find.byType(TextField), 'Ready for preview');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final apply = find.widgetWithText(ActionButton, 'Apply draft');
      final focus = tester.widget<ActionButton>(apply).focusNode!;
      expect(focus.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Apply cancelled'), findsOneWidget);
      expect(find.text('Ready for preview'), findsOneWidget);
      expect(focus.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Dialog dismissed'), findsOneWidget);
      expect(find.text('Ready for preview'), findsOneWidget);
      expect(focus.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Draft applied'), findsOneWidget);
      expect(find.text('Ready for preview'), findsNWidgets(2));
      expect(focus.hasPrimaryFocus, isTrue);
    },
  );

  testWidgets('narrow RTL workbench at 2x can reach and use the draft action', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 440);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: child!,
          ),
        ),
        home: const WorkbenchRecipe(),
      ),
    );
    final field = find.byType(TextField);
    final apply = find.widgetWithText(ActionButton, 'Apply draft');
    expect(
      tester.getTopLeft(_tab('overview')).dy,
      greaterThan(tester.getBottomLeft(_navigation('overview')).dy),
    );
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    expect(field.hitTestable(), findsOneWidget);
    await tester.enterText(field, 'A narrow draft');
    await tester.ensureVisible(apply);
    await tester.pumpAndSettle();
    expect(apply.hitTestable(), findsOneWidget);
    await tester.tap(apply);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('OK'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Draft applied'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
