import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('Roboto')
      ..addFont(
        File(
          'test/assets/Roboto-Regular.ttf',
        ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
      );
    await loader.load();
  });
  for (final brightness in Brightness.values) {
    testWidgets('opt-in compact design / ${brightness.name}', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      debugDisableShadows = false;
      addTearDown(() => debugDisableShadows = true);
      final theme =
          (brightness == Brightness.dark
                  ? LiquidGlassThemeData.dark()
                  : const LiquidGlassThemeData())
              .copyWith(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.indigo,
                  brightness: brightness,
                ),
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                layout: const GlassLayout(iconSize: 18),
                textTheme: const TextTheme(labelLarge: TextStyle(fontSize: 14)),
              );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: brightness,
            fontFamily: 'Roboto',
            extensions: [theme],
          ),
          home: RepaintBoundary(
            key: const ValueKey('design'),
            child: Scaffold(
              body: GlassBackdrop(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Compact controls and independent local overrides',
                        style: TextStyle(fontSize: 22),
                      ),
                      const SizedBox(height: 24),
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Workspace controls'),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                GlassButton(
                                  onPressed: () {},
                                  child: const Text('Open material'),
                                ),
                                const SizedBox(width: 8),
                                const GlassButton(
                                  onPressed: null,
                                  child: Text('Unavailable'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      LiquidGlassTheme.merge(
                        data: (parent) => parent.copyWith(
                          buttonStyle: parent.buttonStyle.copyWith(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          controlStyle: ButtonStyle(
                            foregroundColor: WidgetStatePropertyAll(
                              brightness == Brightness.dark
                                  ? Colors.lightGreenAccent
                                  : Colors.deepPurple,
                            ),
                          ),
                          layout: parent.layout.copyWith(
                            cardPadding: const EdgeInsets.all(12),
                          ),
                        ),
                        child: GlassCard(
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text('Local geometry and state colors'),
                              ),
                              GlassButton(
                                onPressed: () {},
                                child: const Text('Local action'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Touch-safe compact mode keeps a 48 px target',
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: LiquidGlassTheme.merge(
                          data: (parent) => parent.copyWith(
                            tapTargetSize: MaterialTapTargetSize.padded,
                          ),
                          child: GlassButton(
                            onPressed: () {},
                            child: const Text('Touch target'),
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
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('design')),
        matchesGoldenFile('goldens/design-${brightness.name}.png'),
      );
      debugDisableShadows = true;
    });
  }
}
