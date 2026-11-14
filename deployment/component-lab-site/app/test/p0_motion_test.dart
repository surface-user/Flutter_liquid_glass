import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass_component_lab/motion_tryout.dart';
import 'package:glass_component_lab/registry.dart';
import 'package:glass_component_lab/workbench_preview.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

Future<void> motionHost(
  WidgetTester tester,
  Json theme, {
  String? Function(Json)? apply,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: MotionTryout(theme: theme, onApply: apply ?? (_) => null),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> reveal(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

Json runScene() {
  final scene = initialScene();
  scene['modules'] = [
    module('GlassTextField', 1, x: 0, y: 0)
      ..['w'] = 300
      ..['props']['text'] = '初始文字',
    module('GlassButton', 2, x: 0, y: 120)
      ..['w'] = 180
      ..['props']['child'] = textNode('累计一次')
      ..['props']['onPressed'] = 'increment',
    module('Text', 3, x: 0, y: 230)
      ..['w'] = 300
      ..['props']['text'] = '次数 {{count}}',
    module('GlassPageRoute', 4, x: 320, y: 120)..['w'] = 280,
  ];
  return scene;
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
    'presets apply typed motion without mutating source and preserve rejected values',
    (tester) async {
      final theme = themeDefaults();
      final before = jsonEncode(theme);
      Json? saved;
      await motionHost(
        tester,
        theme,
        apply: (value) {
          saved = value;
          return null;
        },
      );
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('快速').last);
      await tester.pumpAndSettle();
      expect(saved!['duration'], 150);
      expect(saved!['pressDuration'], 60);
      expect(jsonEncode(theme), before);
      final button = find.byKey(const ValueKey('motion-press-demo'));
      expect(
        LiquidGlassTheme.of(tester.element(button)).motion.duration,
        const Duration(milliseconds: 150),
      );
      await tester.pumpWidget(const SizedBox());
      await motionHost(tester, theme, apply: (_) => '该方案暂不可用');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('轻柔').last);
      await tester.pumpAndSettle();
      expect(find.text('未应用：该方案暂不可用'), findsOneWidget);
      expect(
        LiquidGlassTheme.of(tester.element(button)).motion.duration,
        const Duration(milliseconds: 280),
      );
      expect(jsonEncode(theme), before);
    },
  );

  testWidgets(
    'real press and material feedback stop under dynamic system reduced motion',
    (tester) async {
      await motionHost(tester, themeDefaults());
      final button = find.byKey(const ValueKey('motion-press-demo'));
      await reveal(tester, button);
      final gesture = await tester.startGesture(tester.getCenter(button));
      // The first frame confirms the touch; the next samples its press animation.
      await tester.pump(const Duration(milliseconds: 110));
      await tester.pump(const Duration(milliseconds: 130));
      Iterable<Transform> transforms() => tester.widgetList<Transform>(
        find.descendant(of: button, matching: find.byType(Transform)),
      );
      expect(transforms().any((t) => t.transform.storage[0] < .999), isTrue);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpAndSettle();
      expect(transforms().every((t) => t.transform.storage[0] == 1), isTrue);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('点击反馈：1 次'), findsOneWidget);
      final surface = find.byKey(const ValueKey('motion-surface-demo'));
      final original = tester.widget<AnimatedGlassSurface>(surface).style;
      final replay = find.byKey(const ValueKey('motion-material-replay'));
      await reveal(tester, replay);
      await tester.tap(replay);
      await tester.pumpAndSettle();
      final changed = tester.widget<AnimatedGlassSurface>(surface).style;
      expect(changed.tintColor, isNot(original.tintColor));
      expect(changed.borderRadius, isNot(original.borderRadius));
      expect(changed.blurSigmaX, original.blurSigmaX);
      expect(changed.blurSigmaY, original.blurSigmaY);
      expect(find.textContaining('当前采用减少动画'), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'motion tryout opens real dialog and page and returns for repeat play',
    (tester) async {
      await motionHost(tester, themeDefaults());
      for (var i = 0; i < 2; i++) {
        final open = find.byKey(const ValueKey('motion-dialog-demo'));
        await reveal(tester, open);
        await tester.tap(open);
        await tester.pumpAndSettle();
        expect(find.byType(GlassDialog), findsOneWidget);
        expect(find.text('打开与关闭使用当前动效方案。'), findsOneWidget);
        await tester.tap(find.text('关闭试用弹窗'));
        await tester.pumpAndSettle();
        expect(find.byType(GlassDialog), findsNothing);
      }
      final page = find.byKey(const ValueKey('motion-page-demo'));
      await reveal(tester, page);
      await tester.tap(page);
      await tester.pumpAndSettle();
      expect(find.text('页面动效试用'), findsOneWidget);
      expect(find.text('进入与返回使用当前动效方案。'), findsOneWidget);
      await tester.tap(find.text('返回动效试用'));
      await tester.pumpAndSettle();
      expect(find.text('页面已返回，可以再次试用。'), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'run session resets text, variables and nested pages without changing the design',
    (tester) async {
      tester.view.physicalSize = const Size(900, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final scene = runScene();
      final before = jsonEncode(scene);
      var exited = false;
      await tester.pumpWidget(
        MaterialApp(
          home: WorkbenchPreview(scene: scene, onExit: () => exited = true),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('次数 0'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '中文运行草稿');
      await tester.pump();
      await tester.tap(find.text('累计一次'));
      await tester.pumpAndSettle();
      expect(find.text('次数 1'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '中文运行草稿',
      );
      expect(jsonEncode(scene), before);
      await tester.tap(find.widgetWithText(GlassButton, '打开示例页面'));
      await tester.pumpAndSettle();
      expect(find.text('新的页面，新的可能。'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('新的页面，新的可能。'), findsNothing);
      expect(find.text('次数 1'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '中文运行草稿',
      );
      await tester.tap(find.widgetWithText(GlassButton, '打开示例页面'));
      await tester.pumpAndSettle();
      expect(find.text('新的页面，新的可能。'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('preview-reset')));
      await tester.pumpAndSettle();
      expect(find.text('新的页面，新的可能。'), findsNothing);
      expect(find.text('次数 0'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '初始文字',
      );
      expect(jsonEncode(scene), before);
      await tester.tap(find.byKey(const ValueKey('preview-exit')));
      expect(exited, isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.binding.hasScheduledFrame, isFalse);
    },
  );

  testWidgets(
    'explicit exit closes a run session even while its own page is open',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => WorkbenchPreview(scene: runScene()),
                  ),
                ),
                child: const Text('开始运行'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('开始运行'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(GlassButton, '打开示例页面'));
      await tester.pumpAndSettle();
      expect(find.text('新的页面，新的可能。'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('preview-exit')));
      await tester.pumpAndSettle();
      expect(find.text('运行预览'), findsNothing);
      expect(find.text('开始运行'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(tester.binding.hasScheduledFrame, isFalse);
    },
  );

  testWidgets(
    'light design uses its real text role inside a dark host and high contrast overrides white Paint',
    (tester) async {
      Color foreground(Finder text) {
        final style = tester.renderObject<RenderParagraph>(text).text.style!;
        return style.foreground?.color ?? style.color!;
      }

      void expectForeground(Finder text, Color expected) {
        final actual = foreground(text);
        // Paint stores float32 channels; pixel values must still match exactly.
        expect(actual.toARGB32(), expected.toARGB32());
        expect(actual.colorSpace, expected.colorSpace);
        expect(actual.a, closeTo(expected.a, 1e-7));
        expect(actual.r, closeTo(expected.r, 1e-7));
        expect(actual.g, closeTo(expected.g, 1e-7));
        expect(actual.b, closeTo(expected.b, 1e-7));
      }

      for (final contrast in [false, true]) {
        final theme = themeDefaults();
        theme['accessibility']['highContrast'] = contrast;
        theme['textTheme']['bodyMedium'] = {
          'fontSize': 18,
          if (contrast)
            'foreground': {'color': '#FFFFFF'}
          else
            'color': '#223344',
        };
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: MotionTryout(theme: theme, onApply: (_) => null),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final expected = contrast
            ? const Color(0xff17233b)
            : const Color(0xff223344);
        expectForeground(find.text('按压反馈'), expected);
        expect(
          tester
              .renderObject<RenderParagraph>(find.text('按压反馈'))
              .text
              .style!
              .fontSize,
          18,
        );
        await tester.pumpWidget(const SizedBox());
        final scene = runScene()..['theme'] = theme;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: WorkbenchPreview(scene: scene),
          ),
        );
        await tester.pumpAndSettle();
        expectForeground(find.byKey(const ValueKey('preview-event')), expected);
        expect(
          tester
              .renderObject<RenderParagraph>(
                find.byKey(const ValueKey('preview-event')),
              )
              .text
              .style!
              .fontSize,
          18,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      }
    },
  );

  testWidgets(
    'custom motion text fits the real selector at 320 wide and 200 percent',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 740);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final theme = themeDefaults();
      theme['motion']['duration'] = 333;
      final before = jsonEncode(theme);
      Json? saved;
      await motionHost(
        tester,
        theme,
        apply: (value) {
          saved = value;
          return null;
        },
      );
      final selector = find.byType(DropdownButtonFormField<String>);
      await reveal(tester, selector);
      final dropdown = tester.widget<DropdownButton<String>>(
        find.descendant(
          of: selector,
          matching: find.byType(DropdownButton<String>),
        ),
      );
      expect(dropdown.value, '自定义');
      expect(dropdown.isDense, isFalse);
      final decorator = tester.widget<InputDecorator>(
        find.descendant(of: selector, matching: find.byType(InputDecorator)),
      );
      expect(decorator.decoration.labelText, isNull);
      expect(find.text('动效方案'), findsOneWidget);
      const label = '自定义（保留当前设置）';
      final text = find
          .descendant(of: selector, matching: find.text(label))
          .first;
      final paragraph = tester.renderObject<RenderParagraph>(text);
      expect(paragraph.didExceedMaxLines, isFalse);
      final boxes = paragraph.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: label.length),
      );
      expect(boxes, isNotEmpty);
      final outer = tester.getRect(selector);
      for (final box in boxes) {
        final topLeft = paragraph.localToGlobal(Offset(box.left, box.top));
        final bottomRight = paragraph.localToGlobal(
          Offset(box.right, box.bottom),
        );
        expect(topLeft.dx, greaterThanOrEqualTo(outer.left - .5));
        expect(bottomRight.dx, lessThanOrEqualTo(outer.right + .5));
        expect(topLeft.dy, greaterThanOrEqualTo(outer.top - .5));
        expect(bottomRight.dy, lessThanOrEqualTo(outer.bottom + .5));
        expect(topLeft.dx, greaterThanOrEqualTo(0));
        expect(bottomRight.dx, lessThanOrEqualTo(320));
      }
      await tester.tap(selector);
      await tester.pumpAndSettle();
      await tester.tap(find.text('标准').last);
      await tester.pumpAndSettle();
      expect(saved!['duration'], 280);
      expect(jsonEncode(theme), before);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'motion and run controls fit short Chinese layouts at enlarged text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final width in [320.0, 390.0, 820.0, 1180.0, 1500.0]) {
        for (final scale in [1.0, 1.3, 2.0]) {
          tester.view.physicalSize = Size(width, 740);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          await motionHost(tester, themeDefaults());
          final replay = find.byKey(const ValueKey('motion-material-replay'));
          await reveal(tester, replay);
          await tester.tap(replay);
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: 'motion/$width/$scale',
          );
          await tester.pumpWidget(const SizedBox());
          await tester.pumpWidget(
            MaterialApp(home: WorkbenchPreview(scene: runScene())),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('原始大小'));
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('适应画面'));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('preview-reset')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'run/$width/$scale');
          await tester.pumpWidget(const SizedBox());
          await tester.pump();
        }
      }
    },
  );
}
