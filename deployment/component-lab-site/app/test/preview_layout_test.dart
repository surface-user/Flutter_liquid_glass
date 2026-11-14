import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';
import 'package:glass_component_lab/registry.dart';
import 'package:glass_component_lab/workbench_preview.dart';

Json sampleScene() => initialScene()
  ..['modules'] = [
    module('GlassIconButton', 1, x: 40, y: 40),
    module('GlassMenu', 2, x: 80, y: 180),
    module('GlassButton', 3, x: 180, y: 320),
  ];

void main() {
  testWidgets(
    'run backdrop fills the viewport and sparse content is centered across window sizes',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final scene = sampleScene();
      final before = jsonEncode(scene);
      await tester.pumpWidget(
        MaterialApp(home: WorkbenchPreview(scene: scene)),
      );
      for (final size in [
        const Size(1500, 900),
        const Size(390, 844),
        const Size(320, 740),
        const Size(1180, 740),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        final viewport = tester.getRect(
          find.byKey(const ValueKey('preview-canvas')),
        );
        final backdrop = tester.getRect(
          find.byKey(const ValueKey('preview-backdrop')),
        );
        expect(backdrop, viewport);
        Rect? content;
        for (final id in ['node-1', 'node-2', 'node-3']) {
          final type = switch (id) {
            'node-1' => GlassIconButton,
            'node-2' => GlassMenu,
            _ => GlassButton,
          };
          final rect = tester.getRect(
            find.descendant(
              of: find.byKey(ValueKey('preview-node-$id')),
              matching: find.byType(type),
            ),
          );
          content = content == null ? rect : content.expandToInclude(rect);
        }
        expect((content!.center - viewport.center).distance, lessThan(1));
        expect(content.left, greaterThanOrEqualTo(viewport.left + 20));
        expect(content.right, lessThanOrEqualTo(viewport.right - 20));
        expect(content.top, greaterThanOrEqualTo(viewport.top + 20));
        expect(content.bottom, lessThanOrEqualTo(viewport.bottom - 20));
        final viewer = tester.widget<InteractiveViewer>(
          find.byKey(const ValueKey('preview-canvas')),
        );
        final scale = viewer.transformationController!.value
            .getMaxScaleOnAxis();
        expect(scale, lessThanOrEqualTo(1));
        if (size.width == 320) {
          expect(scale, lessThan(1));
          await tester.tap(find.byTooltip('原始大小'));
          await tester.pumpAndSettle();
          expect(viewer.transformationController!.value.getMaxScaleOnAxis(), 1);
          await tester.tap(find.byTooltip('适应画面'));
          await tester.pumpAndSettle();
          expect(
            viewer.transformationController!.value.getMaxScaleOnAxis(),
            closeTo(scale, .001),
          );
        }
        expect(tester.takeException(), isNull);
      }
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('打开菜单'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('打开弹窗').last);
        await tester.pumpAndSettle();
        expect(find.text('一点新的想法'), findsOneWidget);
        await tester.tap(find.text('知道了'));
        await tester.pumpAndSettle();
        expect(find.text('一点新的想法'), findsNothing);
      }
      expect(jsonEncode(scene), before);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'typing long Chinese events keeps the viewport stable and resizing retains drafts until reset',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final item = module('GlassTextField', 1, x: 40, y: 80)
        ..['props']['text'] = '设计初值';
      final scene = initialScene()..['modules'] = [item];
      final before = jsonEncode(scene);
      await tester.pumpWidget(
        MaterialApp(home: WorkbenchPreview(scene: scene)),
      );
      await tester.pumpAndSettle();
      final canvas = find.byKey(const ValueKey('preview-canvas'));
      final viewer = tester.widget<InteractiveViewer>(canvas);
      final initial = List<double>.from(
        viewer.transformationController!.value.storage,
      );
      await tester.dragFrom(
        tester.getTopLeft(canvas) + const Offset(10, 10),
        const Offset(30, 20),
      );
      await tester.pumpAndSettle();
      final panned = List<double>.from(
        viewer.transformationController!.value.storage,
      );
      expect(panned, isNot(initial));
      final draft = List.filled(25, '这是一段很长的中文运行草稿').join();
      await tester.enterText(find.byType(TextField), draft);
      await tester.pumpAndSettle();
      expect(viewer.transformationController!.value.storage, panned);
      tester.view.physicalSize = const Size(1500, 900);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        draft,
      );
      final area = tester.getRect(canvas);
      final content = tester.getRect(find.byType(GlassTextField));
      expect((area.center - content.center).distance, lessThan(1));
      await tester.tap(find.byKey(const ValueKey('preview-reset')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '设计初值',
      );
      expect(jsonEncode(scene), before);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
