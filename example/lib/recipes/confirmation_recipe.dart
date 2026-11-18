import 'package:flutter/material.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

void main() => runApp(const ConfirmationRecipeDemo());

Future<bool?> showConfirmation(
  BuildContext context, {
  required String title,
  required Widget content,
  bool glass = false,
  bool useRootNavigator = true,
  bool barrierDismissible = true,
}) {
  final media = MediaQuery.of(context);
  final theme = LiquidGlassTheme.of(context);
  final reduceMotion =
      media.disableAnimations ||
      media.accessibleNavigation ||
      theme.accessibility.reduceMotion ||
      !theme.performance.enableAnimations;

  return showDialog<bool>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: barrierDismissible,
    requestFocus: true,
    animationStyle: reduceMotion ? AnimationStyle.noAnimation : null,
    builder: (dialogContext) {
      final labels = MaterialLocalizations.of(dialogContext);
      final actions = [
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.of(dialogContext).pop<bool>(false),
          child: Text(labels.cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop<bool>(true),
          child: Text(labels.okButtonLabel),
        ),
      ];
      return glass
          ? GlassDialog(
              title: Text(title),
              semanticLabel: title,
              content: content,
              actions: actions,
            )
          : AlertDialog(
              title: Text(title),
              content: content,
              actions: actions,
              scrollable: true,
            );
    },
  );
}

class ConfirmationRecipeDemo extends StatefulWidget {
  const ConfirmationRecipeDemo({super.key});

  @override
  State<ConfirmationRecipeDemo> createState() => _ConfirmationRecipeDemoState();
}

class _ConfirmationRecipeDemoState extends State<ConfirmationRecipeDemo> {
  String _result = '尚未打开';

  Future<void> _open(BuildContext context, {bool glass = false}) async {
    final result = await showConfirmation(
      context,
      title: '确认操作',
      content: const Text('选择确认、取消，或直接关闭弹窗。'),
      glass: glass,
    );
    if (!mounted) return;
    setState(() {
      _result = switch (result) {
        true => '确认',
        false => '取消',
        null => '无值关闭',
      };
    });
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('确认弹窗示例')),
      body: Center(
        child: Builder(
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: () => _open(context),
                child: const Text('打开普通弹窗'),
              ),
              TextButton(
                onPressed: () => _open(context, glass: true),
                child: const Text('打开玻璃弹窗'),
              ),
              Text('结果：$_result'),
            ],
          ),
        ),
      ),
    ),
  );
}
