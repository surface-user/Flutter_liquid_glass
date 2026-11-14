import 'package:flutter/material.dart';

class ParameterInput extends StatefulWidget {
  const ParameterInput({
    super.key,
    required this.value,
    required this.numeric,
    required this.onApply,
    this.allowNull = false,
  });
  final dynamic value;
  final bool numeric;
  final String? Function(dynamic) onApply;
  final bool allowNull;
  @override
  State<ParameterInput> createState() => _ParameterInputState();
}

class _ParameterInputState extends State<ParameterInput> {
  late final controller = TextEditingController(text: display(widget.value));
  late final focus = FocusNode()..addListener(focusChanged);
  String? error;
  String display(dynamic value) => value == null
      ? ''
      : value == '@self'
      ? '当前组件'
      : value.toString();
  void focusChanged() {
    if (!focus.hasFocus) apply();
  }

  void apply() {
    if (controller.text == display(widget.value)) return;
    dynamic parsed = controller.text;
    if (widget.allowNull && controller.text.trim().isEmpty) {
      parsed = null;
    } else if (widget.numeric) {
      parsed = num.tryParse(controller.text);
      if (parsed == null || !parsed.isFinite) {
        setState(() => error = '请输入有效数字');
        return;
      }
    } else if (parsed == '当前组件' && widget.value == '@self') {
      parsed = '@self';
    }
    final result = widget.onApply(parsed);
    if (mounted) setState(() => error = result);
  }

  @override
  void didUpdateWidget(ParameterInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      controller.text = display(widget.value);
      error = null;
    }
  }

  @override
  void dispose() {
    focus.removeListener(focusChanged);
    focus.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    groupId: focus,
    controller: controller,
    focusNode: focus,
    style: const TextStyle(fontSize: 12),
    keyboardType: widget.numeric
        ? const TextInputType.numberWithOptions(decimal: true, signed: true)
        : TextInputType.text,
    onSubmitted: (_) => apply(),
    onTapOutside: (_) => focus.unfocus(),
    onChanged: (_) {
      if (error != null) setState(() => error = null);
    },
    decoration: InputDecoration(
      hintText: widget.value == null ? '未设置，使用默认值' : null,
      errorText: error,
      errorMaxLines: 5,
    ),
  );
}
