import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass_example/recipes/form_recipe.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

void main() {
  testWidgets('theme overrides and interactions compose across surfaces', (
    tester,
  ) async {
    const colors = ColorScheme.dark();
    const globalSelection = Color(0xFF16324F);
    const localSelection = Color(0xFF184B43);
    const globalFocus = Color(0xFF8DC9F3);
    const localFocus = Color(0xFFAFDFC1);
    const instanceFocus = Color(0xFFFFD064);
    const inputFill = Color(0xFF263545);
    const solidKey = ValueKey('solid panel');
    const glassKey = ValueKey('glass panel');
    final formKey = GlobalKey<FormState>();
    final notes = TextEditingController();
    final notesFocus = FocusNode();
    final actionFocus = FocusNode();
    addTearDown(notes.dispose);
    addTearDown(notesFocus.dispose);
    addTearDown(actionFocus.dispose);
    var activations = 0;

    Future<void> show({bool blurEnabled = true, bool highContrast = false}) =>
        tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              colorScheme: colors,
              inputDecorationTheme: const InputDecorationThemeData(
                filled: true,
                fillColor: inputFill,
              ),
              extensions: [
                LiquidGlassThemeData.dark().copyWith(
                  performance: GlassPerformanceConfig(blurEnabled: blurEnabled),
                ),
                const NavigationItemThemeData(
                  selectedBackgroundColor: globalSelection,
                ),
                const ActionButtonThemeData(
                  primary: ActionButtonStyle(focusBorderColor: globalFocus),
                ),
              ],
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(highContrast: highContrast),
              child: child!,
            ),
            home: Scaffold(
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Material(
                    key: solidKey,
                    child: NavigationItem(label: 'Projects', selected: true),
                  ),
                  GlassSurface(
                    key: glassKey,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const NavigationItemTheme(
                          data: NavigationItemThemeData(
                            selectedBackgroundColor: localSelection,
                          ),
                          child: NavigationItem(label: 'Notes', selected: true),
                        ),
                        Builder(
                          builder: (context) => buildFormRecipe(
                            context,
                            formKey: formKey,
                            notes: notes,
                            notesFocus: notesFocus,
                          ),
                        ),
                        ActionButtonTheme(
                          data: const ActionButtonThemeData(
                            style: ActionButtonStyle(
                              focusBorderColor: localFocus,
                            ),
                          ),
                          child: ActionButton(
                            variant: ActionButtonVariant.primary,
                            style: const ActionButtonStyle(
                              focusBorderColor: instanceFocus,
                            ),
                            focusNode: actionFocus,
                            onPressed: () => activations++,
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

    Material materialFor(Finder item) => tester.widget<Material>(
      find.descendant(of: item, matching: find.byType(Material)),
    );

    final filter = find.byType(BackdropFilter);
    final action = find.byType(ActionButton);
    final notesField = find.byType(TextFormField).last;
    Color actionOutline() =>
        (materialFor(action).shape! as OutlinedBorder).side.color;

    await show();
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byKey(solidKey), matching: filter),
      findsNothing,
    );
    expect(
      find.descendant(of: find.byKey(glassKey), matching: filter),
      findsOneWidget,
    );
    expect(
      materialFor(find.widgetWithText(NavigationItem, 'Projects')).color,
      globalSelection,
    );
    expect(
      materialFor(find.widgetWithText(NavigationItem, 'Notes')).color,
      localSelection,
    );
    await tester.enterText(notesField, 'An unsaved draft\nwith two lines');
    await tester.pumpAndSettle();
    expect(notesFocus.hasFocus, isTrue);

    await show(blurEnabled: false);
    await tester.pumpAndSettle();
    expect(find.byKey(glassKey), findsOneWidget);
    expect(filter, findsNothing);
    expect(notesFocus.hasFocus, isTrue);
    expect(tester.state<FormFieldState<String>>(notesField).value, notes.text);
    expect(notes.text, 'An unsaved draft\nwith two lines');
    final notesDecoration = tester
        .widget<InputDecorator>(
          find.descendant(
            of: notesField,
            matching: find.byType(InputDecorator),
          ),
        )
        .decoration;
    expect(notesDecoration.fillColor, inputFill);
    expect(notesDecoration.focusedBorder?.borderSide.color, colors.primary);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(actionFocus.hasFocus, isTrue);
    expect(actionOutline(), instanceFocus);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(activations, 1);

    await show(highContrast: true);
    await tester.pumpAndSettle();
    expect(filter, findsNothing);
    expect(actionFocus.hasFocus, isTrue);
    expect(actionOutline(), colors.onPrimary);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(activations, 2);
    expect(notes.text, 'An unsaved draft\nwith two lines');
    expect(tester.takeException(), isNull);
  });
}
