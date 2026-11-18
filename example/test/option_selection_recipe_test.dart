import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/recipes/option_selection_recipe.dart';

void main() {
  testWidgets('keyboard activation selects and clears the display mode', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: OptionSelectionRecipe()));
    expect(find.text('Mode: Compact'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(find.text('Mode: Detailed'), findsOneWidget);

    await tester.tap(find.text('Unavailable'));
    await tester.pumpAndSettle();
    expect(find.text('Mode: Detailed'), findsOneWidget);

    await tester.tap(find.text('Detailed'));
    await tester.pumpAndSettle();
    expect(find.text('Mode: None'), findsOneWidget);
  });

  testWidgets('a removed destination clears and a disabled one stays inert', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: OptionSelectionRecipe()));
    expect(
      find.text('Archive folder with a deliberately long description'),
      findsOneWidget,
    );

    await tester.tap(find.text('Remove archive'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a folder'), findsOneWidget);

    await tester.tap(
      find.byWidgetPredicate((widget) => widget is DropdownButton),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Archive folder with a deliberately long description'),
      findsNothing,
    );
    await tester.tap(find.text('Offline folder').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Offline folder').hitTestable(), findsOneWidget);

    await tester.tap(find.text('Local folder').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Local folder'), findsOneWidget);

    await tester.tap(find.text('Clear destination'));
    await tester.tap(find.text('Restore archive'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a folder'), findsOneWidget);
  });

  testWidgets('search reports keyboard selection, no results and clear', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: OptionSelectionRecipe()));
    final field = find.byType(TextField);
    await tester.enterText(field, 'FOLDER');
    await tester.pumpAndSettle();
    expect(find.text('Blue folder').hitTestable(), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Suggestion: Green folder'), findsOneWidget);
    expect(tester.widget<TextField>(field).controller!.text, 'Green folder');

    await tester.enterText(field, 'spaceship');
    await tester.pumpAndSettle();
    expect(find.text('No matching folders'), findsOneWidget);
    expect(find.text('Suggestion: None'), findsOneWidget);

    await tester.tap(find.text('Clear search'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
    expect(find.text('No matching folders'), findsNothing);
  });

  testWidgets('narrow RTL layout with large text keeps controls reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 440);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        ),
        home: const OptionSelectionRecipe(),
      ),
    );
    final compact = tester.getCenter(find.text('Compact'));
    final detailed = tester.getCenter(find.text('Detailed'));
    expect(compact.dx, closeTo(detailed.dx, 24));
    expect((compact.dy - detailed.dy).abs(), greaterThanOrEqualTo(48));

    final dropdown = find.byWidgetPredicate(
      (widget) => widget is DropdownButton,
    );
    await tester.ensureVisible(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(dropdown.hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Local folder').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Local folder').hitTestable(), findsOneWidget);

    final search = find.byType(TextField);
    await tester.ensureVisible(search);
    await tester.pumpAndSettle();
    expect(search.hitTestable(), findsOneWidget);
    await tester.enterText(search, 'blue');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blue folder').hitTestable());
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(search).controller!.text, 'Blue folder');
    expect(tester.takeException(), isNull);
  });
}
