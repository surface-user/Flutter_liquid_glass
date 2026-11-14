import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass_component_lab/basic_inspector.dart';
import 'package:glass_component_lab/editor_catalog.dart';
import 'package:glass_component_lab/registry.dart';

void main() {
  test('ordinary catalog contains purposes and unifies the dialog entry', () {
    final names = basicCatalog.map((entry) => entry.type).toSet();
    expect(names.length, basicCatalog.length);
    expect(names, contains('showGlassDialog'));
    expect(
      names.intersection({
        'GlassSurface',
        'AnimatedGlassSurface',
        'LiquidGlassTheme',
        'GlassGroup',
        'GlassPageRoute',
        'MenuItemButton',
        'GlassDialog',
      }),
      isEmpty,
    );
    expect(basicEntryFor('GlassDialog')!.title, '弹窗');
    expect(basicEntryFor('LiquidGlassTheme'), isNull);
    for (final entry in basicCatalog) {
      expect(RegExp(r'[\u4e00-\u9fff]').hasMatch(entry.title), isTrue);
      validateConfig(
        {'type': entry.type, ...createBasicModule(entry.type, 1)['props']},
        'slot:root',
        entry.title,
      );
    }
  });

  test('ordinary cards start static without changing advanced defaults', () {
    final before = jsonEncode(componentDefaults['GlassCard']);
    final card = createBasicModule('GlassCard', 4, at: const Offset(22, 30));
    expect(card['props']['onTap'], 'none');
    expect(card['x'], 22);
    expect(card['y'], 30);
    expect(jsonEncode(componentDefaults['GlassCard']), before);
    expect(() => createBasicModule('GlassGroup', 5), throwsFormatException);
  });

  test('new ordinary dialogs inherit motion without changing old defaults', () {
    final before = jsonEncode(componentDefaults['showGlassDialog']);
    expect(componentDefaults['showGlassDialog']!['motion'], isNotNull);
    expect(createBasicModule('showGlassDialog', 1)['props']['motion'], isNull);
    expect(createBasicModule('GlassDialog', 2)['props']['motion'], isNull);
    expect(jsonEncode(componentDefaults['showGlassDialog']), before);
    expect(module('showGlassDialog', 3)['props']['motion'], isNotNull);
  });

  Future<void> mount(
    WidgetTester tester,
    Widget child, {
    double width = 390,
    double textScale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 900);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'ordinary palette search adds the selected purpose and never shows developer entries',
    (tester) async {
      String? selected;
      await mount(tester, BasicPalette(onAdd: (value) => selected = value));
      await tester.enterText(
        find.byKey(const ValueKey('basic-catalog-search')),
        '弹窗',
      );
      await tester.pumpAndSettle();
      final result = find.byKey(const ValueKey('basic-add-showGlassDialog'));
      expect(result, findsOneWidget);
      expect(
        find.descendant(of: result, matching: find.text('弹窗')),
        findsOneWidget,
      );
      expect(find.text('主题'), findsNothing);
      expect(find.text('组件类型'), findsNothing);
      await tester.tap(result);
      await tester.pumpAndSettle();
      expect(selected, 'showGlassDialog');
    },
  );

  testWidgets(
    'editing text preserves typography, node identity and unrelated values',
    (tester) async {
      var item = createBasicModule('Text', 1);
      item['props']['_nodeId'] = 'retained';
      item['props']['style']['color'] = '#123456';
      item['props']['style']['letterSpacing'] = 2;
      final original = clone(item);
      await mount(
        tester,
        StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: BasicInspector(
              module: item,
              onAdvanced: () {},
              onApply: (next) {
                setState(() => item = next);
                return null;
              },
            ),
          ),
        ),
      );
      final input = find.byKey(const ValueKey('basic-node-1-props.text'));
      await tester.enterText(input, '修改后的中文');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(item['props']['text'], '修改后的中文');
      expect(item['props']['style'], original['props']['style']);
      expect(item['props']['_nodeId'], 'retained');
      expect(original['props']['text'], '写下你的想法');
      expect(find.text('组件类型'), findsNothing);
      expect(find.text('builder'), findsNothing);
    },
  );

  testWidgets(
    'custom children and bound selection are retained instead of flattened',
    (tester) async {
      final item = createBasicModule('GlassCard', 2);
      item['props']['child'] = {
        'type': 'LiquidGlassTheme',
        'data': {'visualDensity': 'compact'},
        'child': textNode('自定义内容'),
      };
      final before = jsonEncode(item);
      var applied = false, advanced = false;
      await mount(
        tester,
        SingleChildScrollView(
          child: BasicInspector(
            module: item,
            onApply: (_) {
              applied = true;
              return null;
            },
            onAdvanced: () => advanced = true,
          ),
        ),
      );
      expect(find.text('此处使用了自定义图文组合，原内容保持不变。'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('basic-node-2-props.child.text')),
        findsNothing,
      );
      await tester.tap(find.text('在高级模式查看').first);
      expect(advanced, isTrue);
      expect(applied, isFalse);
      expect(jsonEncode(item), before);
    },
  );

  testWidgets('sparse legacy children keep their default type when edited', (
    tester,
  ) async {
    var item = createBasicModule('GlassButton', 1)
      ..['props'] = <String, dynamic>{};
    await mount(
      tester,
      StatefulBuilder(
        builder: (context, setState) => SingleChildScrollView(
          child: BasicInspector(
            module: item,
            onAdvanced: () {},
            onApply: (next) {
              validateConfig(
                {'type': next['type'], ...next['props']},
                'slot:root',
                '按钮',
              );
              setState(() => item = next);
              return null;
            },
          ),
        ),
      ),
    );
    final input = find.byKey(const ValueKey('basic-node-1-props.child.text'));
    expect(
      tester
          .widget<TextField>(
            find.descendant(of: input, matching: find.byType(TextField)),
          )
          .controller!
          .text,
      '试试点击我',
    );
    final action = find.byWidgetPredicate(
      (widget) =>
          widget is DropdownButtonFormField<String> &&
          widget.initialValue == 'log',
    );
    expect(action, findsOneWidget);
    await tester.enterText(input, '编辑旧按钮');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(item['props']['child'], {'type': 'Text', 'text': '编辑旧按钮'});
    expect(item['props'].containsKey('style'), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('explicit empty content stays empty until the user writes text', (
    tester,
  ) async {
    var item = createBasicModule('GlassCard', 1);
    item['props']['child'] = null;
    await mount(
      tester,
      StatefulBuilder(
        builder: (context, setState) => SingleChildScrollView(
          child: BasicInspector(
            module: item,
            onAdvanced: () {},
            onApply: (next) {
              validateConfig(
                {'type': next['type'], ...next['props']},
                'slot:root',
                '卡片',
              );
              setState(() => item = next);
              return null;
            },
          ),
        ),
      ),
    );
    final input = find.byKey(const ValueKey('basic-node-1-props.child.text'));
    expect(
      tester
          .widget<TextField>(
            find.descendant(of: input, matching: find.byType(TextField)),
          )
          .controller!
          .text,
      '',
    );
    expect(item['props']['child'], isNull);
    await tester.enterText(input, '新内容');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(item['props']['child'], {'type': 'Text', 'text': '新内容'});
    expect(item['props']['onTap'], 'none');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'menu reorder and removal preserve each item action and identity',
    (tester) async {
      var item = createBasicModule('GlassMenu', 3);
      item['props']['items'][0]['_nodeId'] = 'first-item';
      item['props']['items'][1]['_nodeId'] = 'second-item';
      final dialogAction = {
        'action': 'dialog',
        'builder': {
          'type': 'GlassDialog',
          ...clone(componentDefaults['GlassDialog']!),
        },
      };
      item['props']['items'][1]['onPressed'] = dialogAction;
      await mount(
        tester,
        StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: BasicInspector(
              module: item,
              onAdvanced: () {},
              onApply: (next) {
                setState(() => item = next);
                return null;
              },
            ),
          ),
        ),
      );
      final up = find.byKey(const ValueKey('basic-node-3-items-1-up'));
      await tester.ensureVisible(up);
      await tester.tap(up);
      await tester.pumpAndSettle();
      expect(item['props']['items'][0]['_nodeId'], 'second-item');
      expect(item['props']['items'][0]['onPressed'], dialogAction);
      final remove = find.byKey(const ValueKey('basic-node-3-items-1-remove'));
      await tester.ensureVisible(remove);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(item['props']['items'].length, 1);
      expect(item['props']['items'][0]['_nodeId'], 'second-item');
      final add = find.byKey(const ValueKey('basic-node-3-items-add'));
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(item['props']['items'].length, 2);
      expect(item['props']['items'][1]['child']['text'], '新菜单项');
    },
  );

  testWidgets(
    'appearance selections show the actual selected preset and restore inheritance',
    (tester) async {
      var item = createBasicModule('GlassCard', 1);
      await mount(
        tester,
        StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: BasicInspector(
              module: item,
              onAdvanced: () {},
              onApply: (next) {
                setState(() => item = next);
                return null;
              },
            ),
          ),
        ),
      );
      var current = 'inherit';
      for (final preset in {
        'subtle': '轻透',
        'card': '标准卡片',
        'elevatedCard': '浮起卡片',
        'inherit': '跟随整体外观',
      }.entries) {
        final selector = find.byKey(
          ValueKey('basic-node-1-appearance-$current'),
        );
        await tester.ensureVisible(selector);
        await tester.tap(selector);
        await tester.pumpAndSettle();
        await tester.tap(find.text(preset.value).last);
        await tester.pumpAndSettle();
        final selected = find.byKey(
          ValueKey('basic-node-1-appearance-${preset.key}'),
        );
        expect(
          tester.widget<DropdownButtonFormField<String>>(selected).initialValue,
          preset.key,
        );
        expect(
          item['props']['style'],
          preset.key == 'inherit' ? null : styleJson(presets[preset.key]!),
        );
        current = preset.key;
      }
      final style = styleJson(presets['card']!);
      item['props']['style'] = {
        for (final key in style.keys.toList().reversed) key: style[key],
      };
      await tester.pumpWidget(const SizedBox());
      await mount(
        tester,
        SingleChildScrollView(
          child: BasicInspector(
            module: item,
            onApply: (_) => null,
            onAdvanced: () {},
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('basic-node-1-appearance-card')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'new dialog actions are offered only by the complete ordinary button path',
    (tester) async {
      for (final type in [
        'GlassButton',
        'GlassIconButton',
        'GlassCard',
        'GlassNavigationItem',
        'GlassTab',
        'GlassMenu',
        'GlassToolbar',
        'GlassAppBar',
      ]) {
        final item = createBasicModule(type, 1);
        final props = item['props'] as Json;
        if (type == 'GlassMenu') {
          for (final child in props['items']) {
            child['onPressed'] = 'log';
          }
        }
        await mount(
          tester,
          SingleChildScrollView(
            child: BasicInspector(
              module: item,
              onApply: (_) => null,
              onAdvanced: () {},
            ),
          ),
        );
        final actions = find.byWidgetPredicate(
          (widget) =>
              widget is DropdownButtonFormField<String> &&
              widget.key is ValueKey &&
              (widget.key as ValueKey).value.toString().contains('-action-'),
        );
        for (final widget in tester.widgetList<DropdownButtonFormField<String>>(
          actions,
        )) {
          final control = find.descendant(
            of: find.byKey(widget.key!),
            matching: find.byType(DropdownButton<String>),
          );
          final options = tester
              .widget<DropdownButton<String>>(control)
              .items!
              .map((item) => item.value)
              .toList();
          expect(
            options.contains('dialog'),
            ['GlassButton', 'GlassIconButton'].contains(type),
            reason: '$type/${widget.key}',
          );
        }
        await tester.pumpWidget(const SizedBox());
      }
      var item = createBasicModule('GlassButton', 1);
      await mount(
        tester,
        StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: BasicInspector(
              module: item,
              onApply: (next) {
                setState(() => item = next);
                return null;
              },
              onAdvanced: () {},
            ),
          ),
        ),
      );
      final action = find.byKey(
        const ValueKey('basic-node-1-props.onPressed-action-log'),
      );
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      await tester.tap(find.text('打开说明弹窗').last);
      await tester.pumpAndSettle();
      expect(item['props']['onPressed']['action'], 'dialog');
      expect(item['props']['onPressed']['builder']['type'], 'GlassDialog');
    },
  );

  testWidgets(
    'old non-button dialogs remain unchanged and explicitly open advanced editing',
    (tester) async {
      final item = createBasicModule('GlassCard', 1);
      item['props']['onTap'] = {
        'action': 'dialog',
        'builder': {
          'type': 'GlassDialog',
          ...clone(componentDefaults['GlassDialog']!),
        },
      };
      final before = jsonEncode(item);
      var applied = false, advanced = false;
      await mount(
        tester,
        SingleChildScrollView(
          child: BasicInspector(
            module: item,
            onApply: (_) {
              applied = true;
              return null;
            },
            onAdvanced: () => advanced = true,
          ),
        ),
      );
      expect(find.text('已配置弹窗，内容编辑需进入高级模式。'), findsOneWidget);
      expect(find.text('编辑弹窗内容'), findsNothing);
      final edit = find.text('在高级模式编辑弹窗');
      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();
      expect(advanced, isTrue);
      expect(applied, isFalse);
      expect(jsonEncode(item), before);
    },
  );

  testWidgets(
    'selected Chinese dropdown text remains inside its field at 320 wide and 200 percent',
    (tester) async {
      final button = createBasicModule('GlassButton', 1);
      final card = createBasicModule('GlassCard', 2);
      final custom = createBasicModule('GlassCard', 3);
      custom['props']['onTap'] = {'action': 'focus', 'target': '保留绑定'};
      custom['props']['style'] = {'tintOpacity': .23};
      for (final item in [button, card, custom]) {
        await mount(
          tester,
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: BasicInspector(
                module: item,
                onApply: (_) => null,
                onAdvanced: () {},
              ),
            ),
          ),
          width: 320,
          textScale: 2,
        );
        final fields = find.byType(DropdownButtonFormField<String>);
        for (final field in fields.evaluate().toList()) {
          final selector = find.byWidget(field.widget);
          await tester.ensureVisible(selector);
          await tester.pumpAndSettle();
          final dropdown = tester.widget<DropdownButton<String>>(
            find.descendant(
              of: selector,
              matching: find.byType(DropdownButton<String>),
            ),
          );
          expect(dropdown.isDense, isFalse);
          final selected =
              dropdown.items!
                      .singleWhere((item) => item.value == dropdown.value)
                      .child
                  as Text;
          final label = selected.data!;
          final text = find
              .descendant(of: selector, matching: find.text(label))
              .first;
          final paragraph = tester.renderObject<RenderParagraph>(text);
          expect(paragraph.didExceedMaxLines, isFalse, reason: label);
          final boxes = paragraph.getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: label.length),
          );
          expect(boxes, isNotEmpty, reason: label);
          final outer = tester.getRect(selector);
          for (final box in boxes) {
            final topLeft = paragraph.localToGlobal(Offset(box.left, box.top));
            final bottomRight = paragraph.localToGlobal(
              Offset(box.right, box.bottom),
            );
            expect(
              topLeft.dx,
              greaterThanOrEqualTo(outer.left - .5),
              reason: label,
            );
            expect(
              bottomRight.dx,
              lessThanOrEqualTo(outer.right + .5),
              reason: label,
            );
            expect(
              topLeft.dy,
              greaterThanOrEqualTo(outer.top - .5),
              reason: label,
            );
            expect(
              bottomRight.dy,
              lessThanOrEqualTo(outer.bottom + .5),
              reason: label,
            );
          }
          final decoration = tester.widget<InputDecorator>(
            find.descendant(
              of: selector,
              matching: find.byType(InputDecorator),
            ),
          );
          expect(
            decoration.decoration.labelText,
            isNull,
            reason: 'label is outside the field',
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    },
  );

  testWidgets('ordinary controls fit narrow Chinese layouts at enlarged text', (
    tester,
  ) async {
    for (final width in [320.0, 390.0]) {
      for (final entry in basicCatalog) {
        await mount(
          tester,
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: BasicInspector(
                module: createBasicModule(entry.type, 1),
                onApply: (_) => null,
                onAdvanced: () {},
              ),
            ),
          ),
          width: width,
          textScale: 2,
        );
        expect(tester.takeException(), isNull, reason: '${entry.title}/$width');
        expect(find.text('组件类型'), findsNothing);
        await tester.pumpWidget(const SizedBox());
      }
    }
  });
}
