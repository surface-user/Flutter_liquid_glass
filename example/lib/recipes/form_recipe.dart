import 'package:flutter/material.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

void main() => runApp(const FormRecipeDemo());

class FormRecipeDemo extends StatelessWidget {
  const FormRecipeDemo({super.key});

  ThemeData _theme(ColorScheme colors) => ThemeData(
    colorScheme: colors,
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: colors.surface,
      border: const OutlineInputBorder(),
    ),
  );

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: _theme(ColorScheme.fromSeed(seedColor: Colors.indigo)),
    highContrastTheme: _theme(const ColorScheme.highContrastLight()),
    home: const _FormRecipePage(),
  );
}

class _FormRecipePage extends StatefulWidget {
  const _FormRecipePage();

  @override
  State<_FormRecipePage> createState() => _FormRecipePageState();
}

class _FormRecipePageState extends State<_FormRecipePage> {
  final _formKey = GlobalKey<FormState>();
  final _notes = TextEditingController(text: '示例备注');
  final _notesFocus = FocusNode();
  String? _savedNotes;

  @override
  void dispose() {
    _notes.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('原生表单示例')),
    body: GlassBackdrop(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: GlassSurface(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buildFormRecipe(
                      context,
                      formKey: _formKey,
                      notes: _notes,
                      notesFocus: _notesFocus,
                      onNotesSaved: (value) {
                        setState(() => _savedNotes = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton(
                          onPressed: () {
                            final form = _formKey.currentState!;
                            if (form.validate()) form.save();
                          },
                          child: const Text('校验并读取'),
                        ),
                        TextButton(
                          onPressed: () {
                            _formKey.currentState!.reset();
                            setState(() => _savedNotes = null);
                          },
                          child: const Text('重置'),
                        ),
                      ],
                    ),
                    if (_savedNotes case final notes?) Text('已读取：$notes'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget buildFormRecipe(
  BuildContext context, {
  required GlobalKey<FormState> formKey,
  required TextEditingController notes,
  FocusNode? notesFocus,
  FormFieldSetter<String>? onNotesSaved,
  String? notesError,
  bool notesReadOnly = false,
  bool notesEnabled = true,
}) {
  final colors = Theme.of(context).colorScheme;
  final inherited = InputDecorationTheme.of(context);
  return InputDecorationTheme(
    data: inherited.copyWith(
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.all(12),
      errorMaxLines: 3,
    ),
    child: Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            initialValue: '示例标题',
            decoration: const InputDecoration(labelText: '标题'),
            validator: (value) => (value ?? '').trim().isEmpty ? '请输入标题' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: notes,
            focusNode: notesFocus,
            maxLines: 4,
            enabled: notesEnabled,
            readOnly: notesReadOnly,
            forceErrorText: notesError,
            decoration: const InputDecoration(
              labelText: '备注',
              alignLabelWithHint: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
            validator: (value) => (value ?? '').trim().isEmpty ? '请输入备注' : null,
            onSaved: onNotesSaved,
          ),
        ],
      ),
    ),
  );
}
