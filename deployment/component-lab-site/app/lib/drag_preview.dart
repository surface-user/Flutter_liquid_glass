import 'package:flutter/material.dart';
import 'registry.dart';

class DragPreview extends StatefulWidget {
  const DragPreview({
    super.key,
    required this.item,
    required this.theme,
    this.scale = 1,
  });
  final Json item, theme;
  final double scale;

  @override
  State<DragPreview> createState() => _DragPreviewState();
}

class _DragPreviewState extends State<DragPreview> {
  final runtime = Runtime(() {}, (_) {});

  @override
  void dispose() {
    runtime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = glassTheme(widget.theme);
    final media = MediaQuery.of(context);
    final reduced =
        media.disableAnimations ||
        media.accessibleNavigation ||
        theme.accessibility.reduceMotion ||
        !theme.performance.enableAnimations;
    return IgnorePointer(
      child: ExcludeFocus(
        child: TweenAnimationBuilder<double>(
          key: ValueKey(reduced),
          tween: Tween(begin: reduced ? 1 : .96, end: 1),
          duration: reduced ? Duration.zero : const Duration(milliseconds: 140),
          builder: (_, value, child) => Transform.scale(
            scale: value,
            alignment: Alignment.topLeft,
            child: child,
          ),
          child: Theme(
            data: ThemeData(
              brightness: theme.brightness,
              fontFamily: 'LabSans',
              textTheme: theme.textTheme,
              colorScheme:
                  theme.colorScheme ??
                  ColorScheme.fromSeed(
                    seedColor: theme.accentColor,
                    brightness: theme.brightness,
                  ),
              extensions: [theme],
            ),
            child: MediaQuery(
              // The avatar is a visual copy; it must not animate its own backdrop or take focus.
              data: media.copyWith(
                disableAnimations: true,
                highContrast:
                    media.highContrast || theme.accessibility.highContrast,
              ),
              child: SizedBox(
                width: number(widget.item['w']) * widget.scale,
                height: number(widget.item['h']) * widget.scale,
                child: FittedBox(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: number(widget.item['w']),
                    height: number(widget.item['h']),
                    child: Material(
                      type: MaterialType.transparency,
                      child: Builder(
                        builder: (c) =>
                            moduleView(runtime, widget.item, c, 'drag/root'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
