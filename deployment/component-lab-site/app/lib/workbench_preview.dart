import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';
import 'registry.dart';

/// A disposable run session. No callback can write its state into the design.
class WorkbenchPreview extends StatefulWidget {
  const WorkbenchPreview({super.key, required this.scene, this.onExit});

  final Json scene;
  final VoidCallback? onExit;

  @override
  State<WorkbenchPreview> createState() => _WorkbenchPreviewState();
}

class _WorkbenchPreviewState extends State<WorkbenchPreview> {
  late final Json snapshot = prepareScene(widget.scene);
  int generation = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: const Text('运行预览', maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [
        IconButton(
          key: const ValueKey('preview-reset'),
          tooltip: '重置运行',
          onPressed: () => setState(() => generation++),
          icon: const Icon(Icons.restart_alt),
        ),
        IconButton(
          key: const ValueKey('preview-exit'),
          tooltip: '退出运行',
          onPressed:
              widget.onExit ??
              () {
                final host = Navigator.of(context);
                if (host.canPop()) host.pop();
              },
          icon: const Icon(Icons.close),
        ),
      ],
    ),
    body: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text('输入、选择和页面跳转仅在本次运行中生效。重置可恢复设计初值，退出后不会修改画布。'),
        ),
        Expanded(
          child: _PreviewSession(key: ValueKey(generation), scene: snapshot),
        ),
      ],
    ),
  );
}

class _PreviewSession extends StatefulWidget {
  const _PreviewSession({super.key, required this.scene});
  final Json scene;

  @override
  State<_PreviewSession> createState() => _PreviewSessionState();
}

class _PreviewSessionState extends State<_PreviewSession> {
  late final Json scene = clone(widget.scene);
  late final Runtime runtime = Runtime(
    () {
      if (mounted) revision.value++;
    },
    (message) {
      if (mounted) {
        lastEvent = message.split(' · ').last;
        revision.value++;
      }
    },
  );
  final navigation = GlobalKey<NavigatorState>();
  final viewport = TransformationController();
  final revision = ValueNotifier(0);
  final contentKeys = <String, GlobalKey>{};
  Size? fittedSize;
  String lastEvent = '运行已开始';

  @override
  void dispose() {
    runtime.dispose();
    viewport.dispose();
    revision.dispose();
    super.dispose();
  }

  Rect get contentBounds {
    Rect? bounds;
    for (final m in scene['modules'] as List) {
      final box = contentKeys[m['id']]?.currentContext?.findRenderObject();
      final size = box is RenderBox && box.hasSize
          ? box.size
          : Size(number(m['w']), number(m['h']));
      final rect = Rect.fromLTWH(
        number(m['x']),
        number(m['y']),
        size.width,
        size.height,
      );
      bounds = bounds == null ? rect : bounds.expandToInclude(rect);
    }
    return bounds ?? const Rect.fromLTWH(0, 0, 300, 200);
  }

  void fit(Size available, {bool original = false}) {
    final bounds = contentBounds;
    final scale = original
        ? 1.0
        : math
              .min(
                math.max(1, available.width - 48) / bounds.width,
                math.max(1, available.height - 48) / bounds.height,
              )
              .clamp(.1, 1.0)
              .toDouble();
    viewport.value = Matrix4.diagonal3Values(scale, scale, scale)
      ..setEntry(
        0,
        3,
        (available.width - bounds.width * scale) / 2 - bounds.left * scale,
      )
      ..setEntry(
        1,
        3,
        (available.height - bounds.height * scale) / 2 - bounds.top * scale,
      );
  }

  Widget readableBoard(
    BuildContext context,
    LiquidGlassThemeData theme,
    Widget child,
  ) {
    final contrast =
        MediaQuery.highContrastOf(context) || theme.accessibility.highContrast;
    final dark = theme.brightness == Brightness.dark;
    final background = contrast
        ? dark
              ? const Color(0xff202a3c)
              : const Color(0xffedf1f8)
        : theme.surfaceColor;
    final typography = Theme.of(context).textTheme.bodyMedium!;
    final paint = typography.foreground;
    final foreground = dark ? Colors.white : const Color(0xff17233b);
    final readable = !contrast
        ? typography
        : paint == null
        ? typography.copyWith(color: foreground)
        : typography.copyWith(
            foreground: Paint()
              ..color = foreground
              ..style = paint.style
              ..strokeWidth = paint.strokeWidth,
          );
    return ColoredBox(
      color: background,
      child: DefaultTextStyle(style: readable, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = glassTheme(Map<String, dynamic>.from(scene['theme']));
    final colors =
        theme.colorScheme ??
        ColorScheme.fromSeed(
          seedColor: theme.accentColor,
          brightness: theme.brightness,
        );
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        colorScheme: colors,
        fontFamily: 'LabSans',
        textTheme: theme.textTheme,
        iconTheme: IconThemeData(
          size: theme.layout.iconSize,
          color: theme.foregroundColor,
        ),
      ),
      child: LiquidGlassTheme(
        data: theme,
        child: NavigatorPopHandler<Object?>(
          onPopWithResult: (result) => navigation.currentState?.pop(result),
          child: Navigator(
            key: navigation,
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (runContext) => ValueListenableBuilder<int>(
                valueListenable: revision,
                builder: (_, value, child) => MediaQuery(
                  data: MediaQuery.of(runContext).copyWith(
                    highContrast:
                        MediaQuery.highContrastOf(runContext) ||
                        theme.accessibility.highContrast,
                  ),
                  child: Builder(
                    builder: (boardContext) => readableBoard(
                      boardContext,
                      theme,
                      Column(
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, limits) {
                                if (fittedSize != limits.biggest) {
                                  final available = limits.biggest;
                                  fittedSize = available;
                                  fit(available);
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (mounted && fittedSize == available)
                                      fit(available);
                                  });
                                }
                                final contrast = MediaQuery.highContrastOf(
                                  context,
                                );
                                final viewer = InteractiveViewer(
                                  key: const ValueKey('preview-canvas'),
                                  transformationController: viewport,
                                  alignment: Alignment.topLeft,
                                  constrained: false,
                                  minScale: .1,
                                  maxScale: 2,
                                  boundaryMargin: const EdgeInsets.all(
                                    double.infinity,
                                  ),
                                  child: SizedBox(
                                    width: 1200,
                                    height: 1200,
                                    child: Stack(
                                      clipBehavior: Clip.hardEdge,
                                      children: [
                                        if ((scene['modules'] as List).isEmpty)
                                          Positioned.fromRect(
                                            rect: contentBounds,
                                            child: const Center(
                                              child: Text('画布中还没有可运行的内容'),
                                            ),
                                          ),
                                        for (final m
                                            in scene['modules'] as List)
                                          Positioned(
                                            left: number(m['x']),
                                            top: number(m['y']),
                                            width: number(m['w']),
                                            height: number(m['h']),
                                            child: ClipRect(
                                              key: ValueKey(
                                                'preview-node-${m['id']}',
                                              ),
                                              child: moduleView(
                                                runtime,
                                                Map<String, dynamic>.from(m),
                                                boardContext,
                                                '运行/${m['id']}/root',
                                                contentKey: contentKeys
                                                    .putIfAbsent(
                                                      m['id'],
                                                      () => GlobalKey(),
                                                    ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                                return Stack(
                                  children: [
                                    Positioned.fill(
                                      child: contrast
                                          ? ColoredBox(
                                              key: const ValueKey(
                                                'preview-backdrop',
                                              ),
                                              color:
                                                  theme.brightness ==
                                                      Brightness.dark
                                                  ? const Color(0xff202a3c)
                                                  : const Color(0xffedf1f8),
                                              child: viewer,
                                            )
                                          : GlassBackdrop(
                                              key: const ValueKey(
                                                'preview-backdrop',
                                              ),
                                              child: viewer,
                                            ),
                                    ),
                                    Positioned(
                                      right: 8,
                                      bottom: 8,
                                      child: Material(
                                        color: colors.surface,
                                        borderRadius: BorderRadius.circular(24),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 12,
                                                right: 4,
                                              ),
                                              child: ValueListenableBuilder<Matrix4>(
                                                valueListenable: viewport,
                                                builder: (_, matrix, _) => Text(
                                                  '${(matrix.getMaxScaleOnAxis() * 100).round()}%',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: '适应画面',
                                              onPressed: () =>
                                                  fit(limits.biggest),
                                              icon: const Icon(
                                                Icons.fit_screen,
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: '原始大小',
                                              onPressed: () => fit(
                                                limits.biggest,
                                                original: true,
                                              ),
                                              icon: const Icon(
                                                Icons.center_focus_strong,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Semantics(
                              liveRegion: true,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Tooltip(
                                  message: lastEvent,
                                  child: Text(
                                    lastEvent,
                                    key: const ValueKey('preview-event'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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
