import 'package:flutter/material.dart';
import '../desktop_style.dart';
import 'glass_navigation_item.dart';

/// A controlled tab label with a separate close action; owns no page state.
class GlassTab extends StatelessWidget {
  const GlassTab({
    super.key,
    required this.label,
    this.leading,
    this.selected = false,
    this.onSelected,
    this.onClose,
    this.focusNode,
    this.controlStyle,
  });
  final String label;
  final Widget? leading;
  final bool selected;
  final VoidCallback? onSelected, onClose;
  final FocusNode? focusNode;
  final ButtonStyle? controlStyle;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(
        child: GlassNavigationItem(
          label: label,
          leading: leading,
          selected: selected,
          onPressed: onSelected,
          focusNode: focusNode,
          controlStyle: controlStyle,
        ),
      ),
      if (onClose != null)
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close),
          tooltip:
              '${MaterialLocalizations.of(context).closeButtonTooltip}: $label',
          style: desktopControlStyle(context, controlStyle, icon: true),
        ),
    ],
  );
}
