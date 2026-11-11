import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../example/integration_test/fixtures/desktop_consumer.dart';

void main() {
  setUpAll(() async {
    for (final entry in {
      'Roboto': 'test/assets/Roboto-Regular.ttf',
      'MaterialIcons': 'example/test/assets/MaterialIcons-Regular.otf',
    }.entries) {
      final loader = FontLoader(entry.key)
        ..addFont(
          File(
            entry.value,
          ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
      await loader.load();
    }
  });
  for (final brightness in Brightness.values) {
    testWidgets('desktop visual / ${brightness.name}', (tester) async {
      tester.view.physicalSize = const Size(1000, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      debugDisableShadows = false;
      addTearDown(() => debugDisableShadows = true);
      await tester.pumpWidget(DesktopConsumer(brightness: brightness));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/desktop-${brightness.name}.png'),
      );
      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/desktop-menu-${brightness.name}.png'),
      );
      expect(tester.takeException(), isNull);
      debugDisableShadows = true;
    });
  }
}
