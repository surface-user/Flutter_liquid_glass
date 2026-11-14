import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass_component_lab/main.dart';
import 'package:glass_component_lab/editor_catalog.dart';
import 'package:glass_component_lab/registry.dart';
import 'package:glass_component_lab/workbench_preview.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

Future<void> captureP0(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final image = await tester
        .renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('p0-capture')),
        )
        .toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('../artifacts/p0/screenshots').create(recursive: true);
    await File(
      '../artifacts/p0/screenshots/$name.png',
    ).writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

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

  testWidgets(
    'ordinary mode hides raw types and mode switching preserves complex data',
    (tester) async {
      tester.view.physicalSize = const Size(1500, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const GlassLab());
      await tester.pumpAndSettle();
      final state = tester.state(find.byType(GlassLab)) as dynamic;
      final original = jsonEncode(state.scene);
      expect(find.text('组件类型'), findsNothing);
      expect(find.text('配置'), findsNothing);
      expect(find.text('玻璃表面'), findsNothing);
      expect(find.text('局部主题'), findsNothing);
      expect(find.text('普通模式'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('editor-mode')));
      await tester.pumpAndSettle();
      expect(find.text('高级模式'), findsOneWidget);
      expect(find.text('组件类型'), findsOneWidget);
      expect(find.text('配置'), findsOneWidget);
      expect(jsonEncode(state.scene), original);
      await tester.tap(find.byKey(const ValueKey('editor-mode')));
      await tester.pumpAndSettle();
      expect(jsonEncode(state.scene), original);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'ordinary edit selects content; independent run resets and never changes design',
    (tester) async {
      tester.view.physicalSize = const Size(1500, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const GlassLab());
      await tester.pumpAndSettle();
      final state = tester.state(find.byType(GlassLab)) as dynamic;
      final scene = initialScene();
      scene['modules'] = [
        module('GlassButton', 1, x: 0, y: 0)
          ..['props']['child'] = textNode('累计一次')
          ..['props']['onPressed'] = 'increment',
        module('Text', 2, x: 0, y: 160)..['props']['text'] = '次数 {{count}}',
      ];
      expect(state.commit(scene), isNull);
      await tester.pumpAndSettle();
      final before = jsonEncode(state.scene);
      await tester.tapAt(
        tester.getCenter(
          find.descendant(
            of: find.byKey(const ValueKey('node-1')),
            matching: find.text('累计一次'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(state.events, isEmpty);
      expect(find.text('次数 0'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('run-preview')));
      await tester.pumpAndSettle();
      expect(find.byType(WorkbenchPreview), findsOneWidget);
      await tester.tap(find.text('累计一次'));
      await tester.pumpAndSettle();
      expect(find.text('次数 1'), findsOneWidget);
      expect(jsonEncode(state.scene), before);
      await tester.tap(find.byKey(const ValueKey('preview-reset')));
      await tester.pumpAndSettle();
      expect(find.text('次数 0'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('preview-exit')));
      await tester.pumpAndSettle();
      expect(find.byType(WorkbenchPreview), findsNothing);
      expect(jsonEncode(state.scene), before);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'ordinary dialog edits and tries latest text without exposing types',
    (tester) async {
      tester.view.physicalSize = const Size(1500, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const GlassLab());
      await tester.pumpAndSettle();
      final state = tester.state(find.byType(GlassLab)) as dynamic;
      final scene = initialScene()
        ..['modules'] = [
          createBasicModule('showGlassDialog', 1, at: Offset.zero),
        ];
      expect(state.commit(scene), isNull);
      await tester.pumpAndSettle();
      expect(find.text('组件类型'), findsNothing);
      expect(find.text('目标内容'), findsNothing);
      final body = find.byKey(const ValueKey('dialog-body'));
      await tester.ensureVisible(body);
      await tester.enterText(body, '主界面直接编辑的新正文');
      await tester.pumpAndSettle();
      final trial = find.byKey(const ValueKey('dialog-try'));
      await tester.ensureVisible(trial);
      await tester.pumpAndSettle();
      expect(trial.hitTestable(), findsOneWidget);
      await tester.tap(trial);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(GlassDialog),
          matching: find.text('主界面直接编辑的新正文'),
        ),
        findsOneWidget,
      );
      expect(
        state.scene['modules'][0]['props']['builder']['content']['text'],
        '主界面直接编辑的新正文',
      );
      await tester.tap(
        find.descendant(
          of: find.byType(GlassDialog),
          matching: find.text('关闭'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(GlassDialog), findsNothing);
      expect(find.text('已关闭，未返回结果'), findsOneWidget);
      await tester.tap(find.byTooltip('撤销'));
      await tester.pumpAndSettle();
      expect(
        state.scene['modules'][0]['props']['builder']['content']['text'],
        '这是由真实 Flutter 路由打开的弹窗',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'preview commits the focused design field and canvas cannot autofocus',
    (tester) async {
      tester.view.physicalSize = const Size(1500, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const GlassLab());
      await tester.pumpAndSettle();
      final state = tester.state(find.byType(GlassLab)) as dynamic;
      final scene = initialScene()
        ..['modules'] = [
          createBasicModule('GlassTextField', 1, at: Offset.zero)
            ..['props']['autofocus'] = true,
          createBasicModule('Text', 2, at: const Offset(0, 180)),
        ];
      expect(state.commit(scene), isNull);
      await tester.pumpAndSettle();
      final canvasField = find.descendant(
        of: find.byKey(const ValueKey('node-1')),
        matching: find.byType(TextField),
      );
      expect(
        tester.widget<TextField>(canvasField).focusNode!.hasFocus,
        isFalse,
      );
      expect(state.events, isEmpty);
      state.setState(() => state.selected = 'node-2');
      await tester.pumpAndSettle();
      final input = find.byKey(const ValueKey('basic-node-2-props.text'));
      await tester.enterText(input, '未按回车的中文设计');
      await tester.tap(find.byKey(const ValueKey('run-preview')));
      await tester.pumpAndSettle();
      expect(find.text('未按回车的中文设计'), findsOneWidget);
      expect(state.scene['modules'][1]['props']['text'], '未按回车的中文设计');
      await tester.tap(find.byKey(const ValueKey('preview-exit')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final width in [320.0, 390.0, 820.0, 1180.0, 1500.0]) {
    testWidgets(
      'P0 ordinary Chinese layout at width $width and three font scales',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        for (final scale in [1.0, 1.3, 2.0]) {
          tester.view.physicalSize = Size(width, 1000);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          for (final item in basicCatalog) {
            await tester.pumpWidget(
              const RepaintBoundary(
                key: ValueKey('p0-capture'),
                child: GlassLab(),
              ),
            );
            await tester.pumpAndSettle();
            final state = tester.state(find.byType(GlassLab)) as dynamic;
            final scene = initialScene();
            scene['modules'] = [
              createBasicModule(item.type, 1, at: Offset.zero)
                ..['w'] = 250
                ..['h'] = 600,
            ];
            expect(state.commit(scene), isNull);
            await tester.pumpAndSettle();
            if (width < 1180) {
              state.showInspector(tester.element(find.byType(Scaffold).first));
              await tester.pumpAndSettle();
            }
            expect(find.text('组件类型'), findsNothing);
            expect(find.text('配置'), findsNothing);
            expect(
              tester.takeException(),
              isNull,
              reason: '${item.type}/$width/$scale',
            );
            if ((width == 320 && scale == 2) || (width == 1500 && scale == 1))
              await captureP0(tester, '${item.type}-${width.toInt()}-$scale');
            await tester.pumpWidget(const SizedBox());
            await tester.pump();
          }
        }
      },
    );
  }
}
