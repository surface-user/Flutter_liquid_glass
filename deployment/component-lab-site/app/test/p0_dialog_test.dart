import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass_component_lab/dialog_editor.dart';
import 'package:glass_component_lab/registry.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> editor(
  WidgetTester tester,
  Json initial, {
  ValueChanged<Json>? changed,
  VoidCallback? advanced,
  ValueChanged<String>? event,
  Json? theme,
}) async {
  var current = clone(initial);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(fontFamily: 'LabSans'),
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: DialogEditor(
                module: current,
                onApply: (next) {
                  final scene = initialScene()..['modules'] = [next];
                  validateScene(
                    scene,
                    previous: initialScene()..['modules'] = [current],
                  );
                  changed?.call(next);
                  setState(() => current = next);
                  return null;
                },
                onAdvanced: advanced ?? () {},
                onEvent: event,
                theme: theme,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
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

  test(
    'dialog form recognizes embedded, dedicated and button dialog uses without modifying data',
    () {
      for (final type in [
        'GlassDialog',
        'showGlassDialog',
        'GlassButton',
        'GlassIconButton',
      ]) {
        final value = module(type, 1);
        if (type == 'GlassButton' || type == 'GlassIconButton')
          value['props']['onPressed'] = 'dialog';
        final before = jsonEncode(value);
        expect(DialogEditor.supports(value), isTrue);
        expect(DialogEditor.contentOf(value)!['type'], 'GlassDialog');
        expect(jsonEncode(value), before);
      }
      expect(DialogEditor.supports(module('GlassSurface', 1)), isFalse);
    },
  );

  test(
    'all real dialog entry styles are schema supported and unknown styles are rejected',
    () {
      for (final kind in ['button', 'iconButton', 'textLink', 'actionOnly']) {
        final value = module('showGlassDialog', 1);
        value['props']['triggerKind'] = kind;
        final scene = initialScene()..['modules'] = [value];
        validateScene(scene);
      }
      final value = module('showGlassDialog', 1);
      value['props']['triggerKind'] = 'not-a-real-entry';
      expect(
        () => validateScene(initialScene()..['modules'] = [value]),
        throwsFormatException,
      );
    },
  );

  test(
    'sparse defaults and explicit nulls retain their actual runtime meaning',
    () {
      final sparse = module('showGlassDialog', 1)
        ..['props'] = <String, dynamic>{};
      final before = jsonEncode(sparse);
      expect(DialogEditor.contentOf(sparse)!['title']['text'], '你好，玻璃世界');
      expect(DialogEditor.effectiveProps(sparse)['child']['text'], '打开玻璃弹窗');
      expect(jsonEncode(sparse), before);
      sparse['props']['builder'] = null;
      expect(DialogEditor.contentOf(sparse), isNull);
      final embedded = module('GlassDialog', 2);
      embedded['props']['title'] = null;
      embedded['props']['actions'] = null;
      expect(DialogEditor.contentOf(embedded)!['title'], isNull);
      expect(DialogEditor.contentOf(embedded)!['actions'], isNull);
    },
  );

  testWidgets(
    'editing sparse dialog defaults only materializes the edited branch',
    (tester) async {
      final value = module('showGlassDialog', 1)
        ..['props'] = <String, dynamic>{};
      Json? saved;
      await editor(tester, value, changed: (next) => saved = next);
      final label = find.byKey(const ValueKey('dialog-entry-label'));
      await reveal(tester, label);
      final field = tester.widget<TextField>(
        find.descendant(of: label, matching: find.byType(TextField)),
      );
      expect(field.controller!.text, '打开玻璃弹窗');
      await tester.enterText(label, '查看提示');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect((saved!['props'] as Map).keys.toList(), ['child']);
      final title = find.byKey(const ValueKey('dialog-title'));
      await reveal(tester, title);
      await tester.enterText(title, '修改标题');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect((saved!['props'] as Map).keys.toSet(), {'child', 'builder'});
      expect(
        saved!['props']['builder']['content']['text'],
        '这是由真实 Flutter 路由打开的弹窗',
      );
      expect(saved!['props']['builder']['title']['text'], '修改标题');
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'a null action list can add its first button without altering other content',
    (tester) async {
      final value = module('GlassDialog', 1);
      value['props']['actions'] = null;
      Json? saved;
      await editor(tester, value, changed: (next) => saved = next);
      final add = find.text('添加操作按钮');
      await reveal(tester, add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(saved!['props']['actions'].length, 1);
      expect(saved!['props']['actions'][0]['onPressed'], 'close');
      expect(saved!['props']['content'], value['props']['content']);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'rejected list and return-value edits never mutate the current dialog',
    (tester) async {
      final value = module('showGlassDialog', 1);
      final before = jsonEncode(value);
      var attempts = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DialogEditor(
                module: value,
                onApply: (_) {
                  attempts++;
                  return '本次修改未被接受';
                },
                onAdvanced: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final add = find.text('添加操作按钮');
      await reveal(tester, add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      final state = tester.state(find.byType(DialogEditor)) as dynamic;
      expect(jsonEncode(state.current), before);
      expect(find.text('操作按钮 2'), findsNothing);
      final resultChoice = find.byKey(
        const ValueKey('dialog-button-0-result-none'),
      );
      await reveal(tester, resultChoice);
      await tester.tap(resultChoice);
      await tester.pumpAndSettle();
      await tester.tap(find.text('一段文字').last);
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(jsonEncode(state.current), before);
      expect(jsonEncode(value), before);
      expect(find.byKey(const ValueKey('dialog-button-0-value')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'direct title/body editing preserves text style and clears an optional title',
    (tester) async {
      final value = module('showGlassDialog', 1);
      value['props']['builder']['content']['style'] = {'fontSize': 19};
      Json? saved;
      await editor(tester, value, changed: (next) => saved = next);
      final body = find.byKey(const ValueKey('dialog-body'));
      await reveal(tester, body);
      await tester.enterText(body, '第一段中文说明\n第二段详细说明，保留原来的字体。');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(saved!['props']['builder']['content']['text'], contains('第二段'));
      expect(saved!['props']['builder']['content']['style'], {'fontSize': 19});
      final preview = find.byKey(const ValueKey('dialog-content-preview'));
      expect(
        find.descendant(
          of: preview,
          matching: find.text('第一段中文说明\n第二段详细说明，保留原来的字体。'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: preview,
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        ),
        findsNothing,
      );
      final title = find.byKey(const ValueKey('dialog-title'));
      await reveal(tester, title);
      await tester.enterText(title, '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(saved!['props']['builder']['title'], isNull);
      expect(find.text('组件类型'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'read-only preview uses readable design colors under high contrast',
    (tester) async {
      final theme = themeDefaults();
      theme['brightness'] = 'light';
      theme['accessibility']['highContrast'] = true;
      theme['textTheme']['bodyMedium'] = {
        'foreground': {'color': '#FFFFFF'},
      };
      await editor(tester, module('showGlassDialog', 1), theme: theme);
      final preview = find.byKey(const ValueKey('dialog-content-preview'));
      final text = find.descendant(
        of: preview,
        matching: find.text('这是由真实 Flutter 路由打开的弹窗'),
      );
      final style = DefaultTextStyle.of(tester.element(text)).style;
      expect(
        style.foreground!.color.toARGB32(),
        const Color(0xff17233b).toARGB32(),
      );
      final background =
          tester.widget<Container>(preview).decoration! as BoxDecoration;
      expect(background.color, const Color(0xffedf1f8));
      await reveal(tester, find.text('内容预览（只读）'));
      await tester.tap(find.text('内容预览（只读）'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('dialog-content-preview')),
        findsNothing,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('clicking trial commits the focused body draft before opening', (
    tester,
  ) async {
    Json? saved;
    await editor(
      tester,
      module('showGlassDialog', 1),
      changed: (next) => saved = next,
    );
    final body = find.byKey(const ValueKey('dialog-body'));
    await reveal(tester, body);
    await tester.enterText(body, '还没有按回车的最后一段中文');
    await tester.pump();
    expect(saved, isNull);
    await reveal(tester, find.byKey(const ValueKey('dialog-try')));
    await tester.tap(find.byKey(const ValueKey('dialog-try')));
    await tester.pumpAndSettle();
    expect(saved!['props']['builder']['content']['text'], '还没有按回车的最后一段中文');
    expect(
      find.descendant(
        of: find.byType(GlassDialog),
        matching: find.text('还没有按回车的最后一段中文'),
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(of: find.byType(GlassDialog), matching: find.text('关闭')),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'purpose changes explicitly confirm button replacement and preserve text',
    (tester) async {
      final value = module('showGlassDialog', 1);
      Json? saved;
      await editor(tester, value, changed: (next) => saved = next);
      Future<void> chooseConfirm() async {
        final purpose = find.byKey(const ValueKey('dialog-purpose-info'));
        await reveal(tester, purpose);
        await tester.tap(purpose);
        await tester.pumpAndSettle();
        await tester.tap(find.text('确认操作').last);
        await tester.pumpAndSettle();
      }

      await chooseConfirm();
      await tester.tap(find.text('保留当前按钮'));
      await tester.pumpAndSettle();
      expect(saved, isNull);
      await chooseConfirm();
      await tester.tap(find.text('切换用途').last);
      await tester.pumpAndSettle();
      final content = saved!['props']['builder'];
      expect(content['title'], value['props']['builder']['title']);
      expect(content['content'], value['props']['builder']['content']);
      expect(content['actions'].length, 2);
      expect(content['actions'][0]['onPressed']['result'], '取消');
      expect(content['actions'][1]['onPressed']['result'], '确认');
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'trial shows distinct return values, dismissals and restores trial focus',
    (tester) async {
      final value = module('showGlassDialog', 1);
      value['props']['builder']['actions'] = [
        {
          'type': 'GlassButton',
          'child': textNode('取消'),
          'onPressed': {'action': 'close', 'result': '取消'},
        },
        {
          'type': 'GlassButton',
          'child': textNode('确认'),
          'onPressed': {'action': 'close', 'result': '确认'},
        },
      ];
      final events = <String>[];
      await editor(tester, value, event: events.add);
      Future<void> open() async {
        final trial = find.byKey(const ValueKey('dialog-try'));
        await reveal(tester, trial);
        await tester.tap(trial);
        await tester.pumpAndSettle();
        expect(find.byType(GlassDialog), findsOneWidget);
      }

      for (final choice in ['取消', '确认']) {
        await open();
        await tester.tap(
          find.descendant(
            of: find.byType(GlassDialog),
            matching: find.text(choice),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('返回结果：$choice'), findsOneWidget);
        final trialButton = tester.widget<FilledButton>(
          find.byKey(const ValueKey('dialog-try')),
        );
        expect(trialButton.focusNode!.hasFocus, isTrue);
        expect(events, contains('返回结果：$choice'));
      }
      await open();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('已关闭，未返回结果'), findsOneWidget);
      await open();
      await tester.tapAt(const Offset(2, 2));
      await tester.pumpAndSettle();
      expect(find.byType(GlassDialog), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'non-dismissable barrier stays until the real close button is used',
    (tester) async {
      final value = module('showGlassDialog', 1);
      value['props']['barrierDismissible'] = false;
      await editor(tester, value);
      await reveal(tester, find.byKey(const ValueKey('dialog-try')));
      await tester.tap(find.byKey(const ValueKey('dialog-try')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(2, 2));
      await tester.pumpAndSettle();
      expect(find.byType(GlassDialog), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(GlassDialog),
          matching: find.text('关闭'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(GlassDialog), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('custom content is preserved and advanced entry is explicit', (
    tester,
  ) async {
    final value = module('showGlassDialog', 1);
    value['props']['builder']['content'] = {
      'type': 'Column',
      'children': [textNode('自定义正文')],
    };
    final before = jsonEncode(value);
    var calls = 0, advanced = 0;
    await editor(
      tester,
      value,
      changed: (_) => calls++,
      advanced: () => advanced++,
    );
    expect(find.byKey(const ValueKey('dialog-body')), findsNothing);
    expect(find.textContaining('自定义内容或操作'), findsOneWidget);
    await tester.tap(find.text('在高级模式查看内容'));
    expect(advanced, 1);
    expect(calls, 0);
    expect(jsonEncode(value), before);
    await reveal(tester, find.byKey(const ValueKey('dialog-try')));
    await tester.tap(find.byKey(const ValueKey('dialog-try')));
    await tester.pumpAndSettle();
    expect(find.text('自定义正文'), findsOneWidget);
    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();
    expect(jsonEncode(value), before);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'button, icon and text entries open actual dialogs and log the result',
    (tester) async {
      final events = <String>[];
      final runtime = Runtime(() {}, events.add);
      for (final kind in ['button', 'iconButton', 'textLink']) {
        final props = clone(componentDefaults['showGlassDialog']!);
        props['triggerKind'] = kind;
        props['child'] = textNode('查看说明');
        props['builder']['actions'][0]['onPressed'] = {
          'action': 'close',
          'result': '已阅',
        };
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (c) => runtime.build(
                  {'type': 'showGlassDialog', ...props},
                  c,
                  'entry-$kind',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          kind == 'iconButton' ? find.byTooltip('查看说明') : find.text('查看说明'),
        );
        await tester.pumpAndSettle();
        expect(find.text('你好，玻璃世界'), findsOneWidget);
        await tester.tap(find.text('关闭'));
        await tester.pumpAndSettle();
        expect(events.last, contains('返回 已阅'));
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      runtime.dispose();
    },
  );

  testWidgets(
    'trial route uses design theme and honors global and system reduced motion',
    (tester) async {
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      for (final system in [false, true]) {
        final designTheme = themeDefaults();
        designTheme['brightness'] = 'dark';
        designTheme['accessibility']['reduceMotion'] = !system;
        designTheme['motion']['duration'] = 610;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            FakeAccessibilityFeatures(disableAnimations: system);
        final value = module('showGlassDialog', 1);
        value['props']['motion'] = null;
        await editor(tester, value, theme: designTheme);
        await reveal(tester, find.byKey(const ValueKey('dialog-try')));
        await tester.tap(find.byKey(const ValueKey('dialog-try')));
        await tester.pumpAndSettle();
        final dialogContext = tester.element(find.byType(GlassDialog));
        expect(ModalRoute.of(dialogContext)!.transitionDuration, Duration.zero);
        expect(Theme.of(dialogContext).brightness, Brightness.dark);
        expect(Theme.of(dialogContext).colorScheme.brightness, Brightness.dark);
        expect(
          LiquidGlassTheme.of(dialogContext).accessibility.reduceMotion,
          !system,
        );
        await tester.tap(
          find.descendant(
            of: find.byType(GlassDialog),
            matching: find.text('关闭'),
          ),
        );
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox());
      }
    },
  );

  testWidgets(
    'null local dialog motion inherits the surrounding design duration',
    (tester) async {
      final designTheme = themeDefaults();
      designTheme['motion']['duration'] = 610;
      final runtime = Runtime(() {}, (_) {});
      final props = clone(componentDefaults['showGlassDialog']!);
      props['motion'] = null;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiquidGlassTheme(
              data: glassTheme(designTheme),
              child: Builder(
                builder: (c) => runtime.build(
                  {'type': 'showGlassDialog', ...props},
                  c,
                  'inherit',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('打开玻璃弹窗'));
      await tester.pumpAndSettle();
      final dialogContext = tester.element(find.byType(GlassDialog));
      expect(
        ModalRoute.of(dialogContext)!.transitionDuration,
        const Duration(milliseconds: 610),
      );
      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      runtime.dispose();
    },
  );

  testWidgets(
    'legacy built-in dialog copy is shown in Chinese without rewriting saved data',
    (tester) async {
      final value = module('showGlassDialog', 1);
      value['props']['child'] = textNode('调用 showGlassDialog');
      value['props']['builder']['title'] = textNode('Hello, Glass');
      final before = jsonEncode(value);
      var changes = 0;
      await editor(tester, value, changed: (_) => changes++);
      final label = find.byKey(const ValueKey('dialog-entry-label'));
      final field = tester.widget<TextField>(
        find.descendant(of: label, matching: find.byType(TextField)),
      );
      expect(field.controller!.text, '打开玻璃弹窗');
      final preview = find.byKey(const ValueKey('dialog-content-preview'));
      await reveal(tester, preview);
      expect(
        find.descendant(of: preview, matching: find.text('你好，玻璃世界')),
        findsOneWidget,
      );
      expect(changes, 0);
      expect(jsonEncode(value), before);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'selected dialog options wrap inside the field at 200 percent text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final width in [320.0, 390.0]) {
        tester.view.physicalSize = Size(width, 740);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        final value = module('showGlassDialog', 1);
        value['props']['triggerKind'] = 'actionOnly';
        value['props']['builder']['style'] = {'tintOpacity': .48};
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(fontFamily: 'LabSans'),
            home: Scaffold(
              body: SingleChildScrollView(
                child: SizedBox(
                  width: 248,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: DialogEditor(
                      module: value,
                      onApply: (_) => null,
                      onAdvanced: () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final entry in {
          'entry': 'actionOnly',
          'appearance': 'custom',
        }.entries) {
          final field = find.byKey(
            ValueKey('dialog-${entry.key}-${entry.value}'),
          );
          final selected = find.byKey(
            ValueKey('dialog-selected-${entry.key}-${entry.value}'),
          );
          await reveal(tester, field);
          final text = tester.widget<Text>(selected);
          expect(text.maxLines, isNull);
          expect(text.overflow, isNot(TextOverflow.ellipsis));
          final paragraph = tester.renderObject<RenderParagraph>(selected);
          expect(paragraph.didExceedMaxLines, isFalse);
          final boxes = paragraph.getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: text.data!.length),
          );
          expect(
            boxes.length,
            greaterThanOrEqualTo(2),
            reason: '$width/${entry.key} must wrap',
          );
          for (final box in boxes) {
            expect(box.left, greaterThanOrEqualTo(-.5));
            expect(box.right, lessThanOrEqualTo(paragraph.size.width + .5));
            expect(box.bottom, lessThanOrEqualTo(paragraph.size.height + .5));
          }
          final selectedRect = tester.getRect(selected);
          final fieldRect = tester.getRect(field);
          expect(selectedRect.left, greaterThanOrEqualTo(fieldRect.left));
          expect(selectedRect.right, lessThanOrEqualTo(fieldRect.right));
          expect(selectedRect.top, greaterThanOrEqualTo(fieldRect.top));
          expect(selectedRect.bottom, lessThanOrEqualTo(fieldRect.bottom));
        }
        expect(tester.takeException(), isNull, reason: '$width/200%');
        await tester.pumpWidget(const SizedBox());
      }
    },
  );

  testWidgets(
    'Chinese dialog editor and long content fit narrow screens at enlarged text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final width in [320.0, 390.0]) {
        tester.view.physicalSize = Size(width, 740);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        final value = module('showGlassDialog', 1);
        value['props']['builder']['content']['text'] = List.filled(
          12,
          '中文长正文需要保持可阅读和可关闭。',
        ).join('\n');
        await editor(tester, value);
        await reveal(tester, find.byKey(const ValueKey('dialog-try')));
        await tester.tap(find.byKey(const ValueKey('dialog-try')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$width/200%');
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    },
  );
}
