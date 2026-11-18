import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass_example/recipes/workbench_recipe.dart';

void main() {
  setUpAll(() async {
    for (final entry in {
      'Roboto': '../test/assets/Roboto-Regular.ttf',
      'MaterialIcons': 'test/assets/MaterialIcons-Regular.otf',
    }.entries) {
      final loader = FontLoader(entry.key)
        ..addFont(File(entry.value).readAsBytes().then(ByteData.sublistView));
      await loader.load();
    }
  });

  testWidgets('workbench solid, glass and narrow visual baselines', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1100, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Roboto', colorSchemeSeed: Colors.indigo),
        home: const WorkbenchRecipe(),
      ),
    );
    await tester.pumpAndSettle();
    final preview = find.byKey(const ValueKey('workbench-preview'));
    await expectLater(
      preview,
      matchesGoldenFile('goldens/workbench-solid.png'),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Glass'));
    await tester.pumpAndSettle();
    await expectLater(
      preview,
      matchesGoldenFile('goldens/workbench-glass.png'),
    );

    tester.view.physicalSize = const Size(390, 850);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      preview,
      matchesGoldenFile('goldens/workbench-narrow.png'),
    );
  });
}
