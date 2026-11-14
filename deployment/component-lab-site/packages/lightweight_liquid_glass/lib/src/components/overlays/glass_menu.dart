import 'package:flutter/material.dart';
import '../desktop_style.dart';
import '../../theme/theme.dart';

/// A single-level SDK menu. Items are MenuItemButton widgets with caller actions.
class GlassMenu extends StatefulWidget {
  const GlassMenu({
    super.key,
    required this.trigger,
    required this.items,
    this.enabled = true,
    this.focusNode,
    this.onOpen,
    this.onClose,
    this.controlStyle,
  });
  final Widget trigger;
  final List<Widget> items;
  final bool enabled;

  /// Externally owned focus restored when the menu closes.
  final FocusNode? focusNode;
  final VoidCallback? onOpen, onClose;
  final ButtonStyle? controlStyle;
  @override
  State<GlassMenu> createState() => _GlassMenuState();
}

class _GlassMenuState extends State<GlassMenu> {
  final _controller = MenuController();
  final _focus = FocusNode();
  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(GlassMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((!widget.enabled || widget.items.isEmpty) && _controller.isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && (!widget.enabled || widget.items.isEmpty)) {
          _controller.close();
        }
      });
    } else if (oldWidget.focusNode != widget.focusNode &&
        _controller.isOpen &&
        (oldWidget.focusNode ?? _focus).hasFocus) {
      // Replacing the trigger node detaches its focus from the menu action chain.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _controller.isOpen &&
            widget.enabled &&
            widget.items.isNotEmpty) {
          (widget.focusNode ?? _focus).requestFocus();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = LiquidGlassTheme.of(context);
    final contrast =
        theme.accessibility.highContrast ||
        MediaQuery.maybeOf(context)?.highContrast == true;
    final foreground = contrast
        ? (theme.brightness == Brightness.dark
              ? Colors.white
              : const Color(0xff17233b))
        : theme.foregroundColor;
    final surface = contrast
        ? (theme.brightness == Brightness.dark
              ? const Color(0xff202a3c)
              : const Color(0xffedf1f8))
        : theme.surfaceColor;
    final control = desktopControlStyle(context, widget.controlStyle);
    return MenuButtonTheme(
      data: MenuButtonThemeData(style: control),
      child: MenuAnchor(
        controller: _controller,
        childFocusNode: widget.focusNode ?? _focus,
        consumeOutsideTap: true,
        onOpen: widget.onOpen,
        onClose: () {
          if (mounted && widget.enabled && widget.items.isNotEmpty) {
            (widget.focusNode ?? _focus).requestFocus();
          }
          widget.onClose?.call();
        },
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(surface),
          side: WidgetStatePropertyAll(
            BorderSide(
              color: contrast ? foreground : foreground.withValues(alpha: .3),
              width: contrast ? 2 : 1,
            ),
          ),
        ),
        menuChildren: widget.items,
        builder: (context, controller, child) => TextButton(
          focusNode: widget.focusNode ?? _focus,
          style: control,
          onPressed: !widget.enabled || widget.items.isEmpty
              ? null
              : () =>
                    controller.isOpen ? controller.close() : controller.open(),
          child: widget.trigger,
        ),
      ),
    );
  }
}
