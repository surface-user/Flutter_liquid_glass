import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass_component_lab/main.dart';
import 'package:glass_component_lab/registry.dart';
import 'package:glass_component_lab/labels.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';
import 'package:flutter/services.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('LabSans')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            await File('assets/NotoSansSC.ttf').readAsBytes(),
          ),
        ),
      );
    await loader.load();
  });
  test('layout serialization and malformed imports', () {
    final scene = initialScene();
    validateScene(scene);
    validateScene(jsonDecode(jsonEncode(scene)) as Json);
    final bad = clone(scene);
    bad['modules'][1]['id'] = bad['modules'][0]['id'];
    expect(() => validateScene(bad), throwsFormatException);
    bad['modules'][1]['id'] = 'other';
    bad['modules'][1]['props']['style'] = {'tintOpacity': 3};
    expect(() => validateScene(bad), throwsFormatException);
    expect(() => color('#garbage'), throwsFormatException);
  });
  test('standard component, field and option labels are Chinese', () {
    final names = <String>{...componentDefaults.keys, ...icons.keys};
    void collect(dynamic value) {
      if (value is Map) {
        names.addAll(value.keys.cast<String>());
        for (final child in value.values) {
          collect(child);
        }
      } else if (value is List) {
        for (final child in value) {
          collect(child);
        }
      }
    }

    collect(componentDefaults);
    collect(themeDefaults());
    for (final options in enumOptions.values) {
      names.addAll(options);
    }
    expect(
      names.where(
        (name) => !RegExp(r'[\u4e00-\u9fff]').hasMatch(chineseLabel(name)),
      ),
      isEmpty,
    );
    final saved = jsonEncode(initialScene());
    expect(saved, contains('GlassMenu'));
    expect(saved, contains('onPressed'));
    expect(sampleText('我的自定义文字'), '我的自定义文字');
    expect(sampleText('Hello, Glass'), '你好，玻璃世界');
    expect(chinesePath('node-4/root/items/1'), '模块4 / 主组件 / 菜单项列表 / 1');
  });
  test('all material fields and all geometry/motion policies resolve', () {
    final spec = styleJson(GlassPresets.dialog);
    spec['shape'] = 'circle';
    spec['backgroundGradient'] = {
      'colors': ['#ffffff', '#123456'],
    };
    final s = glassStyle(spec);
    expect(s.shape, BoxShape.circle);
    expect(s.backgroundGradient, isNotNull);
    expect(
      glassStyle({...spec, 'shape': 'rectangle'}, s).shape,
      BoxShape.rectangle,
    );
    final t = themeDefaults();
    t['performance']['blurEnabled'] = false;
    t['accessibility']['reduceMotion'] = true;
    t['layout']['iconSize'] = 18;
    t['motion']['transition'] = 'sharedAxis';
    final theme = glassTheme(t);
    expect(theme.performance.blurEnabled, isFalse);
    expect(theme.accessibility.reduceMotion, isTrue);
    expect(theme.layout.iconSize, 18);
  });
  testWidgets('every library component is actually mountable', (tester) async {
    final runtime = Runtime(() {}, (_) {});
    for (final type in componentDefaults.keys) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 900,
                height: 500,
                child: Builder(
                  builder: (c) => runtime.build(
                    {'type': type, ...clone(componentDefaults[type]!)},
                    c,
                    'test/$type',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: type);
    }
    await tester.pumpWidget(const SizedBox());
    runtime.dispose();
  });
  testWidgets('menu dialog action opens a real dismissible glass dialog', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const RepaintBoundary(
        key: ValueKey('capture'),
        child: GlassLab(initialAdvanced: true),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('打开菜单'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('打开弹窗'));
    await tester.pumpAndSettle();
    expect(find.byType(GlassDialog), findsOneWidget);
    expect(find.text('一点新的想法'), findsOneWidget);
    expect(find.text('内容、动作、几何与材质，都由你决定。'), findsOneWidget);
    await capture(tester, 'menu-dialog-zh.png');
    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();
    expect(find.byType(GlassDialog), findsNothing);
    expect(find.text('打开菜单'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('workbench moving undo and genuine interaction', (tester) async {
    tester.view.physicalSize = const Size(1500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const GlassLab(initialAdvanced: true));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final module = find.byKey(const ValueKey('node-1'));
    final before = tester.getTopLeft(module);
    await tester.drag(
      find.byKey(const ValueKey('header-node-1')),
      const Offset(85, 45),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(module).dx, greaterThan(before.dx + 40));
    await tester.tap(find.byTooltip('撤销'));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(module), before);
    await tester.tap(find.text('试试点击我'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('事件').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('onPressed'), findsNothing);
    expect(find.textContaining('模块2 / 主组件 · 记录事件'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Chinese menu dialog fits narrow screens with enlarged text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final width in [320.0, 390.0]) {
      tester.view.physicalSize = Size(width, 844);
      await tester.pumpWidget(
        const RepaintBoundary(
          key: ValueKey('capture'),
          child: GlassLab(initialAdvanced: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('打开菜单'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('打开弹窗'));
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.byType(Dialog));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(width));
      expect(find.text('知道了').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (width == 320) {
        await capture(tester, 'menu-dialog-zh-320.png');
      }
      await tester.tap(find.text('知道了'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      await tester.pumpWidget(const SizedBox());
    }
  });
  testWidgets('desktop and narrow workspace have no layout overflow', (
    tester,
  ) async {
    for (final size in [
      const Size(1440, 1000),
      const Size(390, 844),
      const Size(320, 740),
      const Size(820, 740),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(const GlassLab(initialAdvanced: true));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$size');
      await tester.pumpWidget(const SizedBox());
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  testWidgets(
    'Chinese inspector and settings remain usable at every breakpoint',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final width in [320.0, 390.0, 820.0, 1180.0, 1500.0]) {
        tester.view.physicalSize = Size(width, 1000);
        await tester.pumpWidget(
          const RepaintBoundary(
            key: ValueKey('capture'),
            child: GlassLab(initialAdvanced: true),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('玻璃实验台'), findsOneWidget);
        expect(find.text('GlassLab'), findsNothing);
        final locale = MaterialLocalizations.of(
          tester.element(find.byType(Scaffold).first),
        );
        expect(locale.backButtonTooltip, '返回');
        if (width < 820) {
          await tester.tap(find.byTooltip('全局主题'));
        } else {
          await tester.tap(find.text('全局主题与样式'));
        }
        await tester.pumpAndSettle();
        for (final section in ['动画设置', '性能设置', '无障碍设置']) {
          expect(
            find.byKey(const ValueKey('properties')),
            findsOneWidget,
            reason: 'settings at width $width',
          );
          if (find.text(section).evaluate().isEmpty) {
            await tester.scrollUntilVisible(
              find.text(section),
              section == '性能设置' ? -250 : 250,
              scrollable: find
                  .descendant(
                    of: find.byKey(const ValueKey('properties')),
                    matching: find.byType(Scrollable),
                  )
                  .first,
              maxScrolls: 60,
            );
          }
          await Scrollable.ensureVisible(
            tester.element(find.text(section)),
            alignment: .5,
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text(section));
          await tester.pumpAndSettle();
          expect(
            find.text(switch (section) {
              '动画设置' => '转场方式',
              '性能设置' => '渲染质量',
              _ => '高对比度',
            }),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull, reason: '$width / $section');
        }
        await tester.ensureVisible(find.text('无障碍设置'));
        await tester.pumpAndSettle();
        if (width == 320 || width == 1500) {
          await capture(tester, 'settings-zh-${width.toInt()}.png');
        }
        expect(tester.takeException(), isNull, reason: '$width');
        await tester.pumpWidget(const SizedBox());
      }
    },
  );
  testWidgets(
    'mouse moving and resizing follow the pointer at different zooms',
    (tester) async {
      tester.view.physicalSize = const Size(1500, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final zoom in [.4, .65, .85, 1.25, 1.5]) {
        await tester.pumpWidget(const GlassLab(initialAdvanced: true));
        await tester.pumpAndSettle();
        final zoomIn = zoom > .85;
        final steps = ((zoom - .85).abs() / .1).ceil();
        for (var i = 0; i < steps; i++) {
          await tester.tap(find.byTooltip(zoomIn ? '放大' : '缩小'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('吸附 8px'));
        await tester.pumpAndSettle();
        final module = find.byKey(const ValueKey('node-1'));
        final before = tester.getTopLeft(module);
        await tester.drag(
          find.byKey(const ValueKey('header-node-1')),
          const Offset(85, 45),
          kind: ui.PointerDeviceKind.mouse,
        );
        await tester.pumpAndSettle();
        final moved = tester.getTopLeft(module);
        expect(moved.dx - before.dx, closeTo(85, 1));
        expect(moved.dy - before.dy, closeTo(45, 1));
        await tester.tap(find.byTooltip('撤销'));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(module), before);
        await tester.tap(find.byTooltip('重做'));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(module), moved);
        await tester.tap(find.byTooltip('撤销'));
        await tester.pumpAndSettle();
        final size = tester.getSize(module);
        await tester.drag(
          find.byIcon(Icons.south_east),
          const Offset(65, 39),
          kind: ui.PointerDeviceKind.mouse,
        );
        await tester.pumpAndSettle();
        final resized = tester.getSize(module);
        // getSize reports canvas units; pointer movement is in screen units.
        expect((resized.width - size.width) * zoom, closeTo(65, 1));
        expect((resized.height - size.height) * zoom, closeTo(39, 1));
        await tester.tap(find.byTooltip('撤销'));
        await tester.pumpAndSettle();
        expect(tester.getSize(module), size);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    },
  );
  testWidgets('capture workbench layout', (tester) async {
    tester.view.physicalSize = const Size(1500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const RepaintBoundary(
        key: ValueKey('capture'),
        child: GlassLab(initialAdvanced: true),
      ),
    );
    await tester.pumpAndSettle();
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('capture')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(png, isNotNull);
      await writeScreenshot(png!.buffer.asUint8List());
      image.dispose();
    });
    await tester.pumpWidget(const SizedBox());
  });
}

Future<void> capture(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('capture')),
  );
  await tester.runAsync(() async {
    await Directory('../artifacts').create(recursive: true);
    final image = await boundary.toImage();
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('../artifacts/$name').writeAsBytes(png!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> writeScreenshot(Uint8List bytes) async {
  await Directory('../artifacts').create(recursive: true);
  await File('../artifacts/workbench.png').writeAsBytes(bytes);
}
