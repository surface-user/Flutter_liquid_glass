import 'package:flutter/material.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

void main() => runApp(const GlassGallery());

class GlassGallery extends StatefulWidget {
  const GlassGallery({super.key});
  @override
  State<GlassGallery> createState() => _GlassGalleryState();
}

class _GlassGalleryState extends State<GlassGallery> {
  bool dark = false, contrast = false, reduced = false, blur = true;
  double opacity = .22, sigma = 12, radius = 28;
  Color accent = const Color(0xff526ae8);
  GlassTransition transition = GlassTransition.fadeSlide;
  @override
  Widget build(BuildContext context) {
    final data =
        (dark ? LiquidGlassThemeData.dark() : const LiquidGlassThemeData())
            .copyWith(
              accentColor: accent,
              performance: GlassPerformanceConfig(blurEnabled: blur),
              accessibility: GlassAccessibilityConfig(
                highContrast: contrast,
                reduceMotion: reduced,
              ),
              motion: GlassMotionSpec(transition: transition),
            );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Liquid / Glass',
      theme: ThemeData(
        fontFamily: 'Roboto',
        useMaterial3: true,
        brightness: dark ? Brightness.dark : Brightness.light,
        colorSchemeSeed: accent,
        extensions: [data],
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 15, height: 1.5),
        ),
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: GlassBackdrop(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, bounds) => SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: bounds.maxWidth < 600 ? 20 : 48,
                    vertical: 28,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: accent,
                                ),
                                child: const Icon(
                                  Icons.blur_on,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'LIQUID / GLASS',
                                  style: TextStyle(
                                    fontSize: 14,
                                    letterSpacing: 2.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              GlassIconButton(
                                icon: Icon(
                                  dark
                                      ? Icons.light_mode_outlined
                                      : Icons.dark_mode_outlined,
                                ),
                                tooltip: 'Toggle theme',
                                onPressed: () => setState(() => dark = !dark),
                              ),
                            ],
                          ),
                          const SizedBox(height: 44),
                          Text(
                            'A little depth.\nA lighter interface.',
                            style: TextStyle(
                              fontSize: bounds.maxWidth < 600 ? 38 : 60,
                              height: 1.05,
                              letterSpacing: -2.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Native Flutter surfaces. Soft light, crisp content, and room to breathe.',
                            style: TextStyle(fontSize: 17),
                          ),
                          const SizedBox(height: 28),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _tag('PURE FLUTTER'),
                              _tag('NO UI DEPENDENCIES'),
                              _tag('MIT LICENSE'),
                            ],
                          ),
                          const SizedBox(height: 36),
                          if (bounds.maxWidth >= 900)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: _preview(context, data),
                                ),
                                const SizedBox(width: 24),
                                Expanded(flex: 4, child: _controls()),
                              ],
                            )
                          else ...[
                            _preview(context, data),
                            const SizedBox(height: 24),
                            _controls(),
                          ],
                          const SizedBox(height: 36),
                          _heading(
                            '02 / SURFACE COLLECTION',
                            'One material. Many expressions.',
                          ),
                          const SizedBox(height: 18),
                          GlassGroup(
                            child: Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                for (final preset in [
                                  (
                                    'Subtle',
                                    GlassPresets.subtle,
                                    Icons.water_drop_outlined,
                                  ),
                                  ('Card', data.cardStyle, Icons.crop_square),
                                  (
                                    'Elevated',
                                    GlassPresets.elevatedCard,
                                    Icons.layers_outlined,
                                  ),
                                  (
                                    'Selected',
                                    GlassPresets.selected,
                                    Icons.check_circle_outline,
                                  ),
                                ])
                                  SizedBox(
                                    width: bounds.maxWidth < 600
                                        ? (bounds.maxWidth - 56) / 2
                                        : 260,
                                    child: GlassCard(
                                      style: preset.$2.copyWith(
                                        tintColor: dark
                                            ? const Color(0xff182235)
                                            : preset.$2.tintColor,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(preset.$3, size: 28),
                                          const SizedBox(height: 30),
                                          Text(
                                            preset.$1,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 19,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text('Clipped. Composable.'),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 36),
                          _heading(
                            '03 / INTERACTION',
                            'Small motions. Clear intent.',
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              GlassButton(
                                onPressed: () => _dialog(context),
                                child: const Text('Open glass dialog'),
                              ),
                              GlassButton(
                                onPressed: () => Navigator.of(context).push(
                                  GlassPageRoute<void>(
                                    context: context,
                                    motion: data.motion,
                                    reduceMotion: reduced,
                                    builder: (context) => const _DetailPage(),
                                  ),
                                ),
                                child: const Text('Explore page transition'),
                              ),
                              const GlassButton(
                                onPressed: null,
                                child: Text('Disabled'),
                              ),
                              DropdownButton<GlassTransition>(
                                value: transition,
                                items: [
                                  for (final value in GlassTransition.values)
                                    DropdownMenuItem(
                                      value: value,
                                      child: Text(value.name),
                                    ),
                                ],
                                onChanged: (value) =>
                                    setState(() => transition = value!),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          const Divider(),
                          const SizedBox(height: 16),
                          const Text(
                            'LIGHTWEIGHT LIQUID GLASS   /   0.1.0',
                            style: TextStyle(fontSize: 11, letterSpacing: 2),
                          ),
                          const SizedBox(height: 12),
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

  Widget _tag(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      border: Border.all(color: dark ? Colors.white24 : Colors.black12),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _heading(String eyebrow, String title) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow,
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 2,
          color: dark ? Colors.white70 : const Color(0xff425476),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        title,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      ),
    ],
  );

  Widget _preview(BuildContext context, LiquidGlassThemeData data) => SizedBox(
    height: 440 + (MediaQuery.textScalerOf(context).scale(1) - 1) * 360,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: dark
                    ? const [Color(0xff202743), Color(0xff385361)]
                    : const [Color(0xffbadbe9), Color(0xffa8b6e4)],
              ),
            ),
          ),
          Positioned(
            left: -35,
            top: -25,
            child: Container(
              width: 240,
              height: 240,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xffeed4e9), Color(0xffb28acf)],
                ),
              ),
            ),
          ),
          Positioned(
            right: -20,
            bottom: -70,
            child: Container(
              width: 290,
              height: 290,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [accent, const Color(0xff6abeb3)],
                ),
              ),
            ),
          ),
          Positioned(top: 20, left: 24, child: _tag('01 / LIVE MATERIAL')),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AnimatedGlassSurface(
                width: 360,
                padding: const EdgeInsets.all(28),
                style: data.cardStyle.copyWith(
                  tintColor: dark ? const Color(0xff182235) : Colors.white,
                  tintOpacity: opacity,
                  blurSigmaX: sigma,
                  blurSigmaY: sigma,
                  borderRadius: BorderRadius.circular(radius),
                  borderGradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white70, Colors.white10, Colors.white54],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_outlined,
                          color: dark ? Colors.white : const Color(0xff26334a),
                        ),
                        const Expanded(
                          child: Text(
                            'LIVE PREVIEW',
                            textAlign: TextAlign.end,
                            style: TextStyle(fontSize: 10, letterSpacing: 1.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Make space\nfor clarity.',
                      style: TextStyle(
                        fontSize: 30,
                        height: 1.1,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Your widgets, through a softer lens.'),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 24,
                      runSpacing: 8,
                      children: [
                        const Text(
                          'Built with Flutter',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          '${sigma.round()}σ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _controls() => GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('MATERIAL LAB', 'Find your balance.'),
        const SizedBox(height: 16),
        _slider(
          'Tint opacity',
          opacity,
          0,
          1,
          (value) => setState(() => opacity = value),
          '${(opacity * 100).round()}%',
        ),
        _slider(
          'Blur strength',
          sigma,
          0,
          24,
          (value) => setState(() => sigma = value),
          '${sigma.round()}σ',
        ),
        _slider(
          'Corner radius',
          radius,
          0,
          64,
          (value) => setState(() => radius = value),
          '${radius.round()}px',
        ),
        Wrap(
          spacing: 12,
          children: [
            for (final color in const [
              Color(0xff526ae8),
              Color(0xff188576),
              Color(0xffa15392),
              Color(0xffc47938),
            ])
              IconButton(
                onPressed: () => setState(() => accent = color),
                tooltip: 'Accent ${color.toARGB32().toRadixString(16)}',
                style: IconButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                ),
                icon: Icon(
                  accent == color ? Icons.check : Icons.circle_outlined,
                  size: 20,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Backdrop blur'),
          value: blur,
          onChanged: (value) => setState(() => blur = value),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('High contrast'),
          value: contrast,
          onChanged: (value) => setState(() => contrast = value),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Reduce motion'),
          value: reduced,
          onChanged: (value) => setState(() => reduced = value),
        ),
      ],
    ),
  );

  Widget _slider(
    String title,
    double value,
    double min,
    double max,
    ValueChanged<double> change,
    String label,
  ) => Column(
    children: [
      Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 13)),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      Slider(value: value, min: min, max: max, onChanged: change, label: label),
    ],
  );

  void _dialog(BuildContext context) {
    showGlassDialog<void>(
      context: context,
      builder: (context) => GlassDialog(
        title: const Text('A moment of clarity'),
        content: const Text(
          'A bounded glass surface, readable content, and native keyboard focus. Ready for whatever you build next.',
        ),
        actions: [
          GlassButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _DetailPage extends StatelessWidget {
  const _DetailPage();
  @override
  Widget build(BuildContext context) => Scaffold(
    extendBodyBehindAppBar: true,
    appBar: const GlassAppBar(title: Text('A lighter transition')),
    body: GlassBackdrop(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.air, size: 48),
                const SizedBox(height: 20),
                const Text(
                  'Less motion. More meaning.',
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 12),
                const Text('Only opacity, position, and gentle scale.'),
                const SizedBox(height: 24),
                GlassButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to the material lab'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
