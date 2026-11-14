import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/config.dart';
import '../core/glass_group.dart';
import '../core/style.dart';
import '../theme/theme.dart';
import 'surfaces/glass_surface.dart';

part 'buttons/glass_button.dart';
part 'buttons/glass_icon_button.dart';
part 'surfaces/glass_card.dart';

class _GlassInteraction extends StatefulWidget {
  const _GlassInteraction({
    required this.style,
    required this.onTap,
    required this.child,
    this.autofocus = false,
    this.focusNode,
    this.controlStyle,
    this.materialControlStyle,
    this.contentBuilder,
  });
  final GlassStyle style;
  final VoidCallback? onTap;
  final Widget child;
  final bool autofocus;
  final FocusNode? focusNode;
  final ButtonStyle? controlStyle;
  final ButtonStyle? materialControlStyle;
  final Widget Function(Set<WidgetState> states)? contentBuilder;

  @override
  State<_GlassInteraction> createState() => _GlassInteractionState();
}

class _GlassInteractionState extends State<_GlassInteraction> {
  bool pressed = false, hovered = false, focused = false;
  final pointer = ValueNotifier<Offset?>(null);

  bool get pointerEnabled {
    final theme = LiquidGlassTheme.of(context);
    return widget.onTap != null &&
        !glassReduceMotion(context) &&
        !theme.accessibility.highContrast &&
        MediaQuery.maybeOf(context)?.highContrast != true &&
        !theme.accessibility.reduceTransparency &&
        theme.performance.quality != GlassQuality.low;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!pointerEnabled) pointer.value = null;
  }

  @override
  void dispose() {
    pointer.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_GlassInteraction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onTap == null) {
      pressed = hovered = focused = false;
      pointer.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final down = enabled && pressed;
    final focus = enabled && focused;
    final hover = enabled && hovered;
    final reduced = glassReduceMotion(context);
    final theme = LiquidGlassTheme.of(context);
    final control = widget.controlStyle;
    final states = <WidgetState>{
      if (!enabled) WidgetState.disabled,
      if (down) WidgetState.pressed,
      if (focus) WidgetState.focused,
      if (hover) WidgetState.hovered,
    };
    final s = widget.style;
    final side = widget.materialControlStyle?.side?.resolve(states);
    final overlay = control?.overlayColor?.resolve(states);
    final amount = down ? .05 : (focus ? .02 : (hover ? .03 : 0.0));
    final tint =
        widget.materialControlStyle?.backgroundColor?.resolve(states) ??
        s.tintColor;
    final blended = overlay == null
        ? null
        : Color.alphaBlend(
            overlay,
            tint.withValues(alpha: tint.a * s.tintOpacity),
          );
    final style = s.copyWith(
      tintColor: blended?.withValues(alpha: 1) ?? tint,
      tintOpacity: blended?.a ?? (s.tintOpacity + amount).clamp(0, 1),
      highlightOpacity: (s.highlightOpacity + amount).clamp(0, 1),
      borderWidth: focus
          ? math.max(2, side?.width ?? s.borderWidth + 2)
          : side?.width ?? s.borderWidth,
      borderColor: focus
          ? (side == null ||
                    side.style == BorderStyle.none ||
                    side.width == 0 ||
                    side.color.a == 0
                ? theme.focusColor
                : side.color)
          : side?.color ?? s.borderColor,
      borderOpacity: focus || side != null ? 1 : s.borderOpacity,
      borderGradient: focus || side != null ? null : s.borderGradient,
      shadowOffset: down ? s.shadowOffset * .5 : s.shadowOffset,
    );
    // Transformed surfaces may overlap neighbours, so isolate their backdrop input.
    final surface = GlassGroup(
      overlapping: true,
      child: GlassSurface(
        style: style,
        child: MouseRegion(
          onHover: (event) {
            if (pointerEnabled) pointer.value = event.localPosition;
          },
          onExit: (_) => pointer.value = null,
          child: CustomPaint(
            foregroundPainter: _PointerHighlight(
              pointer,
              style,
              enabled: pointerEnabled,
            ),
            child: InkWell(
              onTap: widget.onTap,
              autofocus: widget.autofocus,
              focusNode: widget.focusNode,
              canRequestFocus: enabled,
              onHighlightChanged: (value) {
                if (widget.onTap != null && pressed != value) {
                  setState(() => pressed = value);
                }
              },
              onHover: (value) => setState(() => hovered = value),
              onFocusChange: (value) => setState(() => focused = value),
              child: widget.contentBuilder?.call(states) ?? widget.child,
            ),
          ),
        ),
      ),
    );
    // Keep the InkWell mounted so motion changes cannot interrupt gesture cleanup.
    return TweenAnimationBuilder<double>(
      tween: Tween(
        end: reduced || !enabled
            ? 0.0
            : (down ? -1.0 : (focus ? 0.0 : (hover ? .5 : 0.0))),
      ),
      duration: reduced || !enabled
          ? Duration.zero
          : control?.animationDuration ??
                (down
                    ? theme.motion.pressDuration
                    : hover
                    ? theme.motion.hoverDuration
                    : theme.motion.releaseDuration),
      curve: theme.motion.interactionCurve,
      child: surface,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, value < 0 ? -value * 1.5 : 0),
        child: Transform.scale(scale: 1 + value * .02, child: child),
      ),
    );
  }
}

class _PointerHighlight extends CustomPainter {
  _PointerHighlight(this.pointer, this.style, {required this.enabled})
    : super(repaint: pointer);
  final ValueNotifier<Offset?> pointer;
  final GlassStyle style;
  final bool enabled;

  @override
  void paint(Canvas canvas, Size size) {
    final position = pointer.value;
    if (!enabled ||
        position == null ||
        size.isEmpty ||
        style.highlightOpacity == 0)
      return;
    final rect = Offset.zero & size;
    final width = math.min(3.0, math.min(size.width, size.height) / 2);
    final path = Path();
    if (style.shape == BoxShape.circle) {
      path.addOval(rect.deflate(width / 2));
    } else {
      path.addRRect(style.borderRadius.toRRect(rect).deflate(width / 2));
    }
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..shader = RadialGradient(
        center: Alignment(
          position.dx / size.width * 2 - 1,
          position.dy / size.height * 2 - 1,
        ),
        radius: 1,
        colors: [
          style.highlightColor.withValues(
            alpha: style.highlightColor.a * style.highlightOpacity,
          ),
          style.highlightColor.withValues(alpha: 0),
        ],
      ).createShader(rect);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PointerHighlight oldDelegate) =>
      oldDelegate.style != style ||
      oldDelegate.enabled != enabled ||
      oldDelegate.pointer != pointer;
}
