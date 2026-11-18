import 'package:flutter/material.dart';

void main() => runApp(const AnchoredMenuRecipeDemo());

class AnchoredMenuRecipeDemo extends StatefulWidget {
  const AnchoredMenuRecipeDemo({super.key});

  @override
  State<AnchoredMenuRecipeDemo> createState() => _AnchoredMenuRecipeDemoState();
}

class _AnchoredMenuRecipeDemoState extends State<AnchoredMenuRecipeDemo> {
  final _triggerFocus = FocusNode();
  final _firstItemFocus = FocusNode();
  String _lastCommand = '无';
  int _commands = 0;
  int _outsideTaps = 0;

  @override
  void dispose() {
    _triggerFocus.dispose();
    _firstItemFocus.dispose();
    super.dispose();
  }

  void _record(String command) {
    if (!mounted) return;
    setState(() {
      _lastCommand = command;
      _commands++;
    });
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: ThemeData(colorSchemeSeed: Colors.indigo),
    highContrastTheme: ThemeData(
      colorScheme: const ColorScheme.highContrastLight(),
    ),
    home: Scaffold(
      appBar: AppBar(title: const Text('锚定菜单示例')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              Align(
                alignment: AlignmentDirectional.topStart,
                child: TextButton(
                  onPressed: () => setState(() => _outsideTaps++),
                  child: Text('菜单外按钮：$_outsideTaps'),
                ),
              ),
              Center(child: Text('命令：$_lastCommand（$_commands 次）')),
              Align(
                alignment: AlignmentDirectional.bottomEnd,
                child: MenuAnchor(
                  childFocusNode: _triggerFocus,
                  consumeOutsideTap: true,
                  animated: false,
                  onOpen: _firstItemFocus.requestFocus,
                  onClose: () {
                    if (mounted) _triggerFocus.requestFocus();
                  },
                  menuChildren: [
                    MenuItemButton(
                      focusNode: _firstItemFocus,
                      onPressed: () => _record('查看'),
                      child: const Text('查看'),
                    ),
                    const MenuItemButton(child: Text('不可用命令')),
                    MenuItemButton(
                      onPressed: () => _record('刷新'),
                      child: const Text('刷新'),
                    ),
                  ],
                  builder: (context, controller, child) => FilledButton(
                    autofocus: true,
                    focusNode: _triggerFocus,
                    onPressed: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    child: const Text('打开菜单'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
