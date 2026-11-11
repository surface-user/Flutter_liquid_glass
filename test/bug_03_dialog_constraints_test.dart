import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

Widget _host(
  Widget child, {
  double maxWidth = 480,
  DialogThemeData dialogTheme = const DialogThemeData(),
}) => MaterialApp(
  theme: ThemeData(
    platform: TargetPlatform.windows,
    dialogTheme: dialogTheme,
    extensions: [
      LiquidGlassThemeData(layout: GlassLayout(dialogMaxWidth: maxWidth)),
    ],
  ),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('explicit dialog constraints override the SDK outer minimum', (
    tester,
  ) async {
    for (final constraints in [
      const BoxConstraints(maxWidth: 230),
      const BoxConstraints.tightFor(width: 180, height: 160),
    ]) {
      await tester.pumpWidget(
        _host(
          GlassDialog(
            constraints: constraints,
            content: const SizedBox(width: 600, height: 400),
          ),
          dialogTheme: const DialogThemeData(
            constraints: BoxConstraints(minWidth: 360),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final size = tester.getSize(find.byType(GlassSurface));
      expect(size.width, constraints.maxWidth);
      if (constraints.hasTightHeight)
        expect(size.height, constraints.maxHeight);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('themed narrow maximum also bounds Material dialog constraints', (
    tester,
  ) async {
    for (final dialogTheme in [
      const DialogThemeData(),
      const DialogThemeData(constraints: BoxConstraints(minWidth: 360)),
    ]) {
      await tester.pumpWidget(
        _host(
          const GlassDialog(content: SizedBox(width: 600, height: 20)),
          maxWidth: 220,
          dialogTheme: dialogTheme,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(GlassSurface)).width, 220);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'default dialog limits and compatible Material constraints remain',
    (tester) async {
      await tester.pumpWidget(
        _host(const GlassDialog(content: SizedBox(width: 1, height: 1))),
      );
      expect(tester.getSize(find.byType(GlassSurface)).width, 280);
      await tester.pumpWidget(
        _host(const GlassDialog(content: SizedBox(width: 600, height: 20))),
      );
      expect(tester.getSize(find.byType(GlassSurface)).width, 480);
      await tester.pumpWidget(
        _host(
          const GlassDialog(content: SizedBox(width: 600, height: 20)),
          dialogTheme: const DialogThemeData(
            constraints: BoxConstraints(minWidth: 320, maxWidth: 360),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(GlassSurface)).width, 360);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('narrow dialogs keep 2x text and actions scrollable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var actions = 0;
    await tester.pumpWidget(
      _host(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: GlassDialog(
            title: const Text('窄窗口 / Narrow'),
            content: Text(List.filled(12, '中文 and English content.').join(' ')),
            actions: [
              TextButton(onPressed: () => actions++, child: const Text('关闭')),
            ],
          ),
        ),
        maxWidth: 220,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(GlassSurface)).width, 220);
    await tester.scrollUntilVisible(find.text('关闭'), 200);
    await tester.tap(find.text('关闭'));
    expect(actions, 1);
    expect(tester.takeException(), isNull);
  });
}
