import 'package:flutter/material.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

// Test-only consumer, shared by widget, Windows and profile acceptance.
void main() => runApp(const DesktopConsumer());

class DesktopConsumer extends StatefulWidget {
  const DesktopConsumer({
    super.key,
    this.brightness = Brightness.light,
    this.compact = true,
    this.highContrast = false,
    this.noBlur = false,
    this.reduceMotion = false,
  });
  final Brightness brightness;
  final bool compact, highContrast, noBlur, reduceMotion;
  @override
  State<DesktopConsumer> createState() => _DesktopConsumerState();
}

class _DesktopConsumerState extends State<DesktopConsumer> {
  final draft = TextEditingController();
  final inputFocus = FocusNode();
  final menuFocus = FocusNode();
  String selected = 'A';
  bool secondTab = true;
  @override
  void initState() {
    super.initState();
    draft.addListener(_refresh);
  }

  void _refresh() => setState(() {});
  @override
  void dispose() {
    draft.removeListener(_refresh);
    draft.dispose();
    inputFocus.dispose();
    menuFocus.dispose();
    super.dispose();
  }

  Future<void> _dialog(BuildContext context) => showGlassDialog<void>(
    context: context,
    builder: (context) => GlassDialog(
      title: const Text('Desktop dialog'),
      content: const Text('Public entry, local theme and keyboard close.'),
      actions: [
        GlassButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close dialog'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: widget.brightness,
    );
    final glass =
        (widget.brightness == Brightness.dark
                ? LiquidGlassThemeData.dark()
                : const LiquidGlassThemeData())
            .copyWith(
              colorScheme: colors,
              visualDensity: widget.compact
                  ? VisualDensity.compact
                  : VisualDensity.standard,
              tapTargetSize: widget.compact
                  ? MaterialTapTargetSize.shrinkWrap
                  : MaterialTapTargetSize.padded,
              performance: GlassPerformanceConfig(blurEnabled: !widget.noBlur),
              accessibility: GlassAccessibilityConfig(
                highContrast: widget.highContrast,
                reduceMotion: widget.reduceMotion,
              ),
              layout: const GlassLayout(iconSize: 18),
            );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        brightness: widget.brightness,
        colorScheme: colors,
        extensions: [glass],
      ),
      home: Builder(
        builder: (context) => Scaffold(
          appBar: const GlassAppBar(title: Text('Desktop contract fixture')),
          body: GlassBackdrop(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlassToolbar(
                    children: [
                      GlassMenu(
                        key: const ValueKey('desktop-menu'),
                        focusNode: menuFocus,
                        trigger: const Text('Actions'),
                        items: [
                          MenuItemButton(
                            onPressed: () => _dialog(context),
                            child: const Text('Open dialog'),
                          ),
                          MenuItemButton(
                            onPressed: draft.clear,
                            child: const Text('Clear draft'),
                          ),
                          const MenuItemButton(child: Text('Disabled action')),
                        ],
                      ),
                      GlassButton(
                        key: const ValueKey('desktop-dialog'),
                        onPressed: () => _dialog(context),
                        child: const Text('Dialog'),
                      ),
                      const Tooltip(
                        message: 'SDK feedback composition',
                        child: Icon(Icons.info_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GlassTextField(
                    key: const ValueKey('desktop-input'),
                    controller: draft,
                    focusNode: inputFocus,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      labelText: 'Search / draft',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        onPressed: draft.clear,
                        tooltip: 'Clear input',
                        icon: const Icon(Icons.clear),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GlassTab(
                          key: const ValueKey('tab-a'),
                          label: 'Tab A',
                          selected: selected == 'A',
                          onSelected: () => setState(() => selected = 'A'),
                        ),
                      ),
                      if (secondTab)
                        Expanded(
                          child: GlassTab(
                            key: const ValueKey('tab-b'),
                            label: 'Tab B',
                            selected: selected == 'B',
                            onSelected: () => setState(() => selected = 'B'),
                            onClose: () => setState(() {
                              secondTab = false;
                              selected = 'A';
                            }),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: constraints.maxWidth < 500 ? 120 : 180,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                GlassNavigationItem(
                                  key: const ValueKey('nav-a'),
                                  label: 'Group A',
                                  leading: const Icon(Icons.folder_outlined),
                                  selected: selected == 'A',
                                  onPressed: () =>
                                      setState(() => selected = 'A'),
                                ),
                                GlassNavigationItem(
                                  key: const ValueKey('nav-b'),
                                  label: 'Nested item B',
                                  leading: const Icon(
                                    Icons.description_outlined,
                                  ),
                                  indent: 12,
                                  selected: selected == 'B',
                                  onPressed: () =>
                                      setState(() => selected = 'B'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GlassCard(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Selection: $selected'),
                                    Text('Draft: ${draft.text}'),
                                    Text(
                                      'Composition: ${draft.value.composing.start}:${draft.value.composing.end}',
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'No application data is managed by this fixture.',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
