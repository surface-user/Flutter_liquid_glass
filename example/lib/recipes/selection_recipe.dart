import 'package:flutter/material.dart';

void main() => runApp(const SelectionRecipeDemo());

enum _Density { comfortable, compact, unavailable }

class SelectionRecipeDemo extends StatefulWidget {
  const SelectionRecipeDemo({super.key});

  @override
  State<SelectionRecipeDemo> createState() => _SelectionRecipeDemoState();
}

class _SelectionRecipeDemoState extends State<SelectionRecipeDemo> {
  bool _enabled = true;
  bool? _includeDetails = false;
  _Density? _density = _Density.comfortable;
  bool _showPreview = false;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: ThemeData(colorSchemeSeed: Colors.indigo),
    highContrastTheme: ThemeData(
      colorScheme: const ColorScheme.highContrastLight(),
    ),
    home: Scaffold(
      appBar: AppBar(title: const Text('选择与开关示例')),
      body: SafeArea(
        child: ListView(
          children: [
            SwitchListTile(
              title: const Text('允许修改选项'),
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
            ),
            CheckboxListTile(
              title: const Text('显示详细信息'),
              value: _includeDetails,
              tristate: true,
              onChanged: _enabled
                  ? (value) => setState(() => _includeDetails = value)
                  : null,
            ),
            RadioGroup<_Density>(
              groupValue: _density,
              onChanged: (value) => setState(() => _density = value),
              child: Column(
                children: [
                  RadioListTile<_Density>(
                    title: const Text('宽松布局'),
                    value: _Density.comfortable,
                    enabled: _enabled,
                  ),
                  const RadioListTile<_Density>(
                    title: Text('不可用的布局'),
                    value: _Density.unavailable,
                    enabled: false,
                  ),
                  RadioListTile<_Density>(
                    title: const Text('紧凑布局'),
                    value: _Density.compact,
                    enabled: _enabled,
                  ),
                ],
              ),
            ),
            SwitchListTile(
              title: const Text('显示预览'),
              value: _showPreview,
              onChanged: _enabled
                  ? (value) => setState(() => _showPreview = value)
                  : null,
            ),
          ],
        ),
      ),
    ),
  );
}
