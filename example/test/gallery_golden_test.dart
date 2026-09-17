import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass_example/main.dart';

void main() {
  setUpAll(() async {
    for (final entry in {
      'Roboto': '../test/assets/Roboto-Regular.ttf',
      'MaterialIcons': 'test/assets/MaterialIcons-Regular.otf',
    }.entries) {
      final font = FontLoader(entry.key)
        ..addFont(
          File(
            entry.value,
          ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
      await font.load();
    }
  });
  for (final size in [const Size(1280, 1600), const Size(390, 1000)]) {
    testWidgets('gallery actual rendering ${size.width}', (tester) async {
      debugDisableShadows = false;
      addTearDown(() => debugDisableShadows = true);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const GlassGallery());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(GlassGallery),
        matchesGoldenFile('goldens/gallery-${size.width.toInt()}-light.png'),
      );
      await tester.tap(find.byTooltip('Toggle theme'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(GlassGallery),
        matchesGoldenFile('goldens/gallery-${size.width.toInt()}-dark.png'),
      );
      await tester.scrollUntilVisible(find.text('Open glass dialog'), 450);
      await tester.tap(find.text('Open glass dialog'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(GlassGallery),
        matchesGoldenFile('goldens/dialog-${size.width.toInt()}.png'),
      );
      debugDisableShadows = true;
    });
  }
  testWidgets('small screen supports enlarged text', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const GlassGallery());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
