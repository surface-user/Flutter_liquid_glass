import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass_example/recipes/form_recipe.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

const _globalFillColor = Color(0xFFEEF1F6);
const _globalPadding = EdgeInsets.all(8);

Widget _host(WidgetBuilder builder, {bool withoutBlur = false}) => MaterialApp(
  theme: ThemeData(
    inputDecorationTheme: const InputDecorationThemeData(
      filled: true,
      fillColor: _globalFillColor,
      border: OutlineInputBorder(),
      contentPadding: _globalPadding,
    ),
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      child: Builder(
        builder: (context) {
          final form = builder(context);
          return withoutBlur
              ? GlassSurface(
                  style: const GlassStyle(blurEnabled: false),
                  child: form,
                )
              : form;
        },
      ),
    ),
  ),
);

void main() {
  final title = find.byType(TextFormField).first;
  final notes = find.byType(TextFormField).last;

  testWidgets('demo validates, reads values and resets to the initial text', (
    tester,
  ) async {
    await tester.pumpWidget(const FormRecipeDemo());
    await tester.enterText(title, '');
    await tester.enterText(notes, '新的\n多行备注');
    await tester.tap(find.text('校验并读取'));
    await tester.pumpAndSettle();
    expect(find.text('请输入标题'), findsOneWidget);
    expect(find.textContaining('已读取：'), findsNothing);

    await tester.enterText(title, '新标题');
    await tester.tap(find.text('校验并读取'));
    await tester.pumpAndSettle();
    expect(find.text('请输入标题'), findsNothing);
    expect(find.text('已读取：新的\n多行备注'), findsOneWidget);

    await tester.tap(find.text('重置'));
    await tester.pumpAndSettle();
    expect(find.text('示例标题'), findsOneWidget);
    expect(find.text('示例备注'), findsOneWidget);
    expect(find.textContaining('已读取：'), findsNothing);
  });

  testWidgets('input decorations inherit, with local and per-field overrides', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: '例');
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      _host(
        (context) => buildFormRecipe(
          context,
          formKey: formKey,
          notes: controller,
          notesFocus: focus,
        ),
        withoutBlur: true,
      ),
    );

    InputDecorator decorator(Finder field) => tester.widget<InputDecorator>(
      find.descendant(of: field, matching: find.byType(InputDecorator)),
    );
    final titleDecoration = decorator(title).decoration;
    final notesDecoration = decorator(notes).decoration;
    expect(titleDecoration.fillColor, _globalFillColor);
    expect(titleDecoration.border, isA<OutlineInputBorder>());
    expect(titleDecoration.contentPadding, const EdgeInsets.all(12));
    expect(notesDecoration.fillColor, _globalFillColor);
    expect(
      notesDecoration.contentPadding,
      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    );

    await tester.tap(notes);
    await tester.pumpAndSettle();
    expect(decorator(notes).isFocused, isTrue);
    expect(notesDecoration.focusedBorder?.borderSide.width, 2);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(formKey.currentState!.validate(), isTrue);
  });

  testWidgets('external errors block validation and rebuild retains editing', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: '例');
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    Widget host({String? error}) => _host(
      (context) => buildFormRecipe(
        context,
        formKey: formKey,
        notes: controller,
        notesFocus: focus,
        notesError: error,
      ),
    );
    await tester.pumpWidget(host());
    await tester.showKeyboard(notes);
    const composing = TextEditingValue(
      text: '中文输入',
      selection: TextSelection.collapsed(offset: 3),
      composing: TextRange(start: 1, end: 4),
    );
    tester.testTextInput.updateEditingValue(composing);
    await tester.pump();
    expect(controller.value, composing);
    expect(formKey.currentState!.validate(), isTrue);

    await tester.pumpWidget(host(error: '备注不可用'));
    expect(controller.value, composing);
    expect(focus.hasFocus, isTrue);
    expect(find.text('备注不可用'), findsOneWidget);
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pumpWidget(host());
    expect(find.text('备注不可用'), findsNothing);
    expect(formKey.currentState!.validate(), isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.text = '仍由调用方持有';
    expect(focus.hasFocus, isFalse);
    await tester.pumpWidget(host());
    expect(find.text('仍由调用方持有'), findsOneWidget);
    focus.requestFocus();
    await tester.pump();
    expect(focus.hasFocus, isTrue);
  });

  testWidgets('read-only and disabled fields remain usable at 2× text size', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(
      text: List.filled(6, '用于测试换行和窄窗口的中文备注').join(),
    );
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 600);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    Widget host({required bool readOnly, required bool enabled}) => _host(
      (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(2)),
        child: buildFormRecipe(
          context,
          formKey: formKey,
          notes: controller,
          notesFocus: focus,
          notesReadOnly: readOnly,
          notesEnabled: enabled,
          notesError: '请输入可用于校验的完整备注内容',
        ),
      ),
    );

    await tester.pumpWidget(host(readOnly: true, enabled: true));
    final editable = find.descendant(
      of: notes,
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(editable).readOnly, isTrue);
    expect(tester.widget<EditableText>(editable).maxLines, 4);
    final error = find.text('请输入可用于校验的完整备注内容');
    expect(error, findsOneWidget);
    expect(tester.getSize(error).height, greaterThan(40));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(host(readOnly: false, enabled: false));
    await tester.tap(notes);
    await tester.pump();
    expect(focus.hasFocus, isFalse);
    expect(tester.takeException(), isNull);
  });
}
