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
  bool fitted = false;
  String lastEvent = '运行已开始';

  @override
  void dispose() {
    runtime.dispose();
    viewport.dispose();
    revision.dispose();
    super.dispose();
  }

  Size get boardSize {
    double width = 300, height = 200;
    for (final m in scene['modules'] as List) {
      width = math.max(width, number(m['x']) + number(m['w']) + 24);
      height = math.max(height, number(m['y']) + number(m['h']) + 24);
    }
    return Size(width, height);
  }

  void fit(Size available) {
    final size = boardSize;
    final scale = math
        .min(available.width / size.width, available.height / size.height)
        .clamp(.1, 1.0)
        .toDouble();
    viewport.value = Matrix4.diagonal3Values(scale, scale, 1);
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
                                if (!fitted) {
                                  fitted = true;
                                  fit(limits.biggest);
                                }
                                final contrast = MediaQuery.highContrastOf(
                                  context,
                                );
                                final size = boardSize;
                                return Stack(
                                  children: [
                                    Positioned.fill(
                                      child: ColoredBox(
                                        color: contrast
                                            ? theme.brightness ==
                                                      Brightness.dark
                                                  ? const Color(0xff202a3c)
                                                  : const Color(0xffedf1f8)
                                            : theme.surfaceColor,
                                        child: InteractiveViewer(
                                          key: const ValueKey('preview-canvas'),
                                          transformationController: viewport,
                                          constrained: false,
                                          minScale: .1,
                                          maxScale: 2,
                                          boundaryMargin: const EdgeInsets.all(
                                            40,
                                          ),
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: contrast
                                                  ? theme.brightness ==
                                                            Brightness.dark
                                                        ? const Color(
                                                            0xff202a3c,
                                                          )
                                                        : const Color(
                                                            0xffedf1f8,
                                                          )
                                                  : null,
                                              gradient: contrast
                                                  ? null
                                                  : LinearGradient(
                                                      colors:
                                                          theme.brightness ==
                                                              Brightness.dark
                                                          ? [
                                                              colors
                                                                  .primaryContainer,
                                                              colors
                                                                  .tertiaryContainer,
                                                              colors
                                                                  .secondaryContainer,
                                                            ]
                                                          : const [
                                                              Color(0xffb4c5ff),
                                                              Color(0xffd8bbed),
                                                              Color(0xffb0e0df),
                                                            ],
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                    ),
                                            ),
                                            child: SizedBox(
                                              width: size.width,
                                              height: size.height,
                                              child: Stack(
                                                clipBehavior: Clip.hardEdge,
                                                children: [
                                                  if ((scene['modules'] as List)
                                                      .isEmpty)
                                                    const Center(
                                                      child: Text(
                                                        '画布中还没有可运行的内容',
                                                      ),
                                                    ),
                                                  for (final m
                                                      in scene['modules']
                                                          as List)
                                                    Positioned(
                                                      left: number(m['x']),
                                                      top: number(m['y']) + 28,
                                                      width: number(m['w']),
                                                      height: math.max(
                                                        0,
                                                        number(m['h']) - 28,
                                                      ),
                                                      child: ClipRect(
                                                        child: Align(
                                                          alignment:
                                                              Alignment.topLeft,
                                                          child: runtime.build(
                                                            {
                                                              'type': m['type'],
                                                              ...m['props']
                                                                  as Map,
                                                            },
                                                            boardContext,
                                                            '运行/${m['id']}/root',
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
                                    Positioned(
                                      right: 8,
                                      bottom: 8,
                                      child: Material(
                                        color: colors.surface,
                                        borderRadius: BorderRadius.circular(24),
                                        child: Wrap(
                                          children: [
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
                                              onPressed: () => viewport.value =
                                                  Matrix4.identity(),
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
                              child: Text(
                                lastEvent,
                                key: const ValueKey('preview-event'),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
