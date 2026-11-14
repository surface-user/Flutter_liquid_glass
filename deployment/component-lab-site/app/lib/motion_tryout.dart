import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';
import 'registry.dart';

const motionPresets = <String, Json>{
  '标准': {
    'transition': 'fadeSlide',
    'duration': 280,
    'reverseDuration': 220,
    'pressDuration': 90,
    'hoverDuration': 160,
    'releaseDuration': 180,
    'surfaceDuration': 240,
    'curve': 'easeOutCubic',
    'reverseCurve': 'easeInCubic',
    'interactionCurve': 'easeOutCubic',
  },
  '轻柔': {
    'transition': 'scaleFade',
    'duration': 420,
    'reverseDuration': 320,
    'pressDuration': 120,
    'hoverDuration': 220,
    'releaseDuration': 280,
    'surfaceDuration': 400,
    'curve': 'easeOutCubic',
    'reverseCurve': 'easeInCubic',
    'interactionCurve': 'easeOutCubic',
  },
  '快速': {
    'transition': 'fade',
    'duration': 150,
    'reverseDuration': 120,
    'pressDuration': 60,
    'hoverDuration': 90,
    'releaseDuration': 110,
    'surfaceDuration': 140,
    'curve': 'easeOut',
    'reverseCurve': 'easeIn',
    'interactionCurve': 'easeOut',
  },
};

/// Ordinary motion controls use the same widgets and routes as the workbench.
class MotionTryout extends StatefulWidget {
  const MotionTryout({super.key, required this.theme, required this.onApply});

  final Json theme;
  final String? Function(Json motion) onApply;

  @override
  State<MotionTryout> createState() => _MotionTryoutState();
}

class _MotionTryoutState extends State<MotionTryout> {
  late Json current = _readMotion();
  bool reduced = false, alternate = false;
  int presses = 0;
  String status = '按住按钮、切换材质或打开浮层，分别试用效果。';

  Json _readMotion() => {
    ...motionDefaults(),
    ...Map<String, dynamic>.from(widget.theme['motion'] as Map? ?? {}),
  };

  @override
  void didUpdateWidget(MotionTryout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (jsonEncode(oldWidget.theme) != jsonEncode(widget.theme)) {
      current = _readMotion();
    }
  }

  void applyPreset(String name) {
    final next = {...current, ...motionPresets[name]!};
    final error = widget.onApply(clone(next));
    setState(() {
      if (error == null) current = next;
      status = error == null ? '已应用$name动效，可在下方试用。' : '未应用：$error';
    });
  }

  Future<void> openDialog(BuildContext context) async {
    await showGlassDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) => GlassDialog(
        title: const Text('弹窗动效'),
        content: const Text('打开与关闭使用当前动效方案。'),
        actions: [
          GlassButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('关闭试用弹窗'),
          ),
        ],
      ),
    );
    if (mounted) setState(() => status = '弹窗已关闭，可以再次试用。');
  }

  Future<void> openPage(BuildContext context) async {
    await Navigator.of(context).push<void>(
      GlassPageRoute<void>(
        context: context,
        builder: (pageContext) => Scaffold(
          appBar: AppBar(title: const Text('页面动效试用')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('进入与返回使用当前动效方案。'),
                    const SizedBox(height: 16),
                    GlassButton(
                      onPressed: () => Navigator.of(pageContext).pop(),
                      child: const Text('返回动效试用'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (mounted) setState(() => status = '页面已返回，可以再次试用。');
  }

  @override
  Widget build(BuildContext context) {
    final data = clone(widget.theme)..['motion'] = current;
    final base = glassTheme(data);
    final effective = base.copyWith(
      accessibility: base.accessibility.copyWith(
        reduceMotion: base.accessibility.reduceMotion || reduced,
      ),
    );
    final scheme =
        effective.colorScheme ??
        ColorScheme.fromSeed(
          seedColor: effective.accentColor,
          brightness: effective.brightness,
        );
    final name = motionPresets.entries
        .where((e) => e.value.entries.every((v) => current[v.key] == v.value))
        .map((e) => e.key)
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('动效试用', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('动效方案', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          key: ValueKey('motion-preset-${name ?? 'custom'}'),
          initialValue: name ?? '自定义',
          isExpanded: true,
          isDense: false,
          itemHeight: null,
          decoration: const InputDecoration(),
          items: [
            if (name == null)
              const DropdownMenuItem(
                value: '自定义',
                child: Text(
                  '自定义（保留当前设置）',
                  style: TextStyle(fontSize: 12),
                  maxLines: 3,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
            for (final preset in motionPresets.keys)
              DropdownMenuItem(
                value: preset,
                child: Text(
                  preset,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 3,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null && motionPresets.containsKey(value))
              applyPreset(value);
          },
        ),
        SwitchListTile(
          key: const ValueKey('motion-reduced'),
          contentPadding: EdgeInsets.zero,
          title: const Text('试用减少动画'),
          subtitle: const Text('仅影响下方试用；系统或主题限制始终优先。'),
          value: reduced,
          onChanged: (value) => setState(() => reduced = value),
        ),
        Theme(
          data: ThemeData(
            useMaterial3: true,
            colorScheme: scheme,
            fontFamily: 'LabSans',
            textTheme: effective.textTheme,
          ),
          child: LiquidGlassTheme(
            data: effective,
            child: Builder(
              builder: (demoContext) {
                final media = MediaQuery.of(demoContext);
                final motionReduced =
                    media.disableAnimations ||
                    media.accessibleNavigation ||
                    effective.accessibility.reduceMotion ||
                    !effective.performance.enableAnimations;
                final contrast =
                    MediaQuery.highContrastOf(demoContext) ||
                    effective.accessibility.highContrast;
                final surface = effective.defaultStyle.copyWith(
                  tintColor: alternate ? scheme.primary : scheme.surface,
                  tintOpacity: alternate ? .35 : .16,
                  borderRadius: BorderRadius.circular(alternate ? 36 : 16),
                );
                final foreground = effective.brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xff17233b);
                final typography = Theme.of(demoContext).textTheme.bodyMedium!;
                final paint = typography.foreground;
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
                return DefaultTextStyle(
                  style: readable,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: contrast
                          ? effective.brightness == Brightness.dark
                                ? const Color(0xff202a3c)
                                : const Color(0xffedf1f8)
                          : null,
                      gradient: contrast
                          ? null
                          : LinearGradient(
                              colors: [
                                scheme.primaryContainer,
                                scheme.tertiaryContainer,
                              ],
                            ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            motionReduced
                                ? '当前采用减少动画：即时变化，仍保留焦点和操作反馈。'
                                : '当前采用正常动效。',
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '按压反馈',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const Text('悬停、按住或用键盘聚焦下方按钮。'),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: GlassButton(
                              key: const ValueKey('motion-press-demo'),
                              onPressed: () => setState(() => presses++),
                              child: const Text('试按一下'),
                            ),
                          ),
                          Text('点击反馈：$presses 次'),
                          const Divider(height: 24),
                          const Text(
                            '材质过渡',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const Text('切换底色和圆角，观察表面的变化。'),
                          const SizedBox(height: 8),
                          AnimatedGlassSurface(
                            key: const ValueKey('motion-surface-demo'),
                            style: surface,
                            padding: const EdgeInsets.all(16),
                            child: Text(alternate ? '第二种材质' : '第一种材质'),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              key: const ValueKey('motion-material-replay'),
                              onPressed: () =>
                                  setState(() => alternate = !alternate),
                              icon: const Icon(Icons.replay),
                              label: const Text('切换并重播材质'),
                            ),
                          ),
                          const Divider(height: 24),
                          const Text(
                            '弹窗与页面过渡',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const Text('真正打开后再关闭或返回；每次打开均可重播。'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              GlassButton(
                                key: const ValueKey('motion-dialog-demo'),
                                onPressed: () => openDialog(demoContext),
                                child: const Text('试用弹窗'),
                              ),
                              GlassButton(
                                key: const ValueKey('motion-page-demo'),
                                onPressed: () => openPage(demoContext),
                                child: const Text('试用页面'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(status, key: const ValueKey('motion-status')),
      ],
    );
  }
}
