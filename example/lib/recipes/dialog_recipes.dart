import 'package:flutter/material.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

void main() => runApp(const DialogRecipesDemo());

AnimationStyle? _dialogAnimationStyle(BuildContext context) {
  final media = MediaQuery.of(context);
  final glassTheme = LiquidGlassTheme.of(context);
  final reduceMotion =
      media.disableAnimations ||
      media.accessibleNavigation ||
      glassTheme.accessibility.reduceMotion ||
      !glassTheme.performance.enableAnimations;
  return reduceMotion ? AnimationStyle.noAnimation : null;
}

class DialogRecipesDemo extends StatelessWidget {
  const DialogRecipesDemo({super.key});

  @override
  Widget build(BuildContext context) =>
      const MaterialApp(home: _DialogRecipesPage());
}

class _DialogRecipesPage extends StatefulWidget {
  const _DialogRecipesPage();

  @override
  State<_DialogRecipesPage> createState() => _DialogRecipesPageState();
}

class _DialogRecipesPageState extends State<_DialogRecipesPage> {
  String _title = '示例标题';
  String _outcome = '尚未编辑';

  Future<void> _openInfo() => showDialog<void>(
    context: context,
    requestFocus: true,
    animationStyle: _dialogAnimationStyle(context),
    builder: (dialogContext) => AlertDialog(
      title: const Text('关于标题'),
      semanticLabel: '关于标题',
      scrollable: true,
      content: const Text(
        '标题会显示在列表和搜索结果中。可以用简短的词说明条目的主题，'
        '也可以在标题中加上课程、日期或版本，用于区分相似的条目。\n\n'
        '如果标题太长，列表中的标题可能只显示开头。建议将最重要的词放在前面，'
        '把完整说明留给正文。有计划改名时，留意其他人是否已用现有标题查找条目。\n\n'
        '可以随时打开编辑弹窗修改标题。选择取消或关闭时，当前标题会继续保留。',
      ),
      actions: [
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(MaterialLocalizations.of(dialogContext).closeButtonLabel),
        ),
      ],
    ),
  );

  Future<void> _editTitle() async {
    final formKey = GlobalKey<FormState>();
    final initialTitle = _title;
    final result = await showDialog<({String? title})>(
      context: context,
      requestFocus: true,
      animationStyle: _dialogAnimationStyle(context),
      builder: (dialogContext) {
        final labels = MaterialLocalizations.of(dialogContext);
        String? submittedTitle;

        bool isCurrent() => ModalRoute.of(dialogContext)?.isCurrent == true;

        void close(String? title) {
          if (isCurrent()) Navigator.of(dialogContext).pop((title: title));
        }

        void submit() {
          if (!isCurrent()) return;
          final form = formKey.currentState!;
          if (!form.validate()) return;
          form.save();
          close(submittedTitle);
        }

        return AlertDialog(
          title: const Text('编辑标题'),
          semanticLabel: '编辑标题',
          scrollable: true,
          content: Form(
            key: formKey,
            child: TextFormField(
              autofocus: true,
              initialValue: initialTitle,
              decoration: const InputDecoration(labelText: '标题'),
              textInputAction: TextInputAction.done,
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? '请输入标题' : null,
              onSaved: (value) => submittedTitle = value?.trim(),
              onFieldSubmitted: (_) => submit(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => close(null),
              child: Text(labels.cancelButtonLabel),
            ),
            FilledButton(onPressed: submit, child: Text(labels.okButtonLabel)),
          ],
        );
      },
    );
    if (!mounted) return;
    setState(() {
      if (result?.title case final title?) _title = title;
      _outcome = switch (result) {
        null => '无值关闭',
        (title: null) => '取消',
        (title: _) => '已修改',
      };
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('弹窗示例')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('当前标题：$_title'),
            FilledButton(
              autofocus: true,
              onPressed: _editTitle,
              child: const Text('修改标题'),
            ),
            TextButton(onPressed: _openInfo, child: const Text('查看说明')),
            Text('结果：$_outcome'),
          ],
        ),
      ),
    ),
  );
}
