import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass_component_lab/main.dart';
import 'package:glass_component_lab/registry.dart';
import 'package:glass_component_lab/labels.dart';
import 'package:glass_component_lab/parameter_input.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

dynamic sample(String kind) {
  if (kind == 'list:color') return ['#4263EB', '#70D8CF'];
  if (kind == 'list:number') return [0, 1];
  if (kind.startsWith('state:'))
    return {
      'default': sample(kind.substring(6)),
      'hovered': sample(kind.substring(6)),
    };
  if (kind.startsWith('list:')) return [sample(kind.substring(5))];
  if (kind.startsWith('slot:'))
    return switchComponent(
      {},
      slotTypes(kind.substring(5)).first,
      slot: kind.substring(5),
    );
  if (kind.startsWith('enum:')) return enumValues(kind.substring(5))!.first;
  return switch (kind) {
    'number' => 24,
    'string' => '中文测试',
    'bool' || 'selected' => true,
    'color' => '#4263EB',
    'insets' => 8,
    'radius' || 'controlShape' => 12,
    'size' => [80, 48],
    'offset' => [1, 4],
    'material' => styleJson(GlassPresets.card),
    'textStyle' => {'fontSize': 18},
    'constraints' => {'maxWidth': 240, 'maxHeight': 300},
    'gradient' => {
      'type': 'linear',
      'colors': ['#4263EB', '#70D8CF'],
    },
    'side' || 'paint' || 'inputBorder' => {'color': '#4263EB'},
    'action' => {'action': 'log'},
    'binding' => {'bind': 'selected', 'default': false},
    'motion' => motionDefaults(),
    'dialogMotion' || 'pageMotion' => {'duration': 160, 'transition': 'fade'},
    'theme' => themeDefaults(),
    'route' => {'name': '测试路由'},
    'control' || 'customControl' => {'foregroundColor': '#4263EB'},
    'scheme' => {'seedColor': '#4263EB'},
    'textTheme' => {
      'bodyMedium': {'fontSize': 18},
    },
    'decoration' => {'hintText': '中文占位提示'},
    'any' => {'自定义数据': '保留'},
    _ => null,
  };
}

Future<void> mount(
  WidgetTester tester,
  Runtime runtime,
  dynamic spec, {
  double width = 600,
  double height = 700,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            height: height,
            child: Align(
              alignment: Alignment.topLeft,
              child: Builder(builder: (c) => runtime.build(spec, c, 'probe')),
            ),
          ),
        ),
      ),
    ),
  );
  if (spec is Map &&
      spec['type'] == 'GlassBackdrop' &&
      spec['animate'] == true) {
    await tester.pump(const Duration(milliseconds: 200));
  } else {
    await tester.pumpAndSettle();
  }
}

Future<void> screenshot(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('capture')),
    );
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('../artifacts/contracts').create(recursive: true);
    await File(
      '../artifacts/contracts/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
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
  test('all 22 types and all 484 root conversions satisfy their schemas', () {
    expect(componentDefaults.length, 22);
    for (final from in componentDefaults.keys) {
      final old = {'type': from, ...clone(componentDefaults[from]!)};
      validateConfig(old, 'slot:root', from);
      for (final to in componentDefaults.keys) {
        final next = switchComponent(old, to);
        validateConfig(next, 'slot:root', '$from -> $to');
        expect(
          next.keys.toSet().difference(schemaFor('component:$to').keys.toSet()),
          isEmpty,
        );
      }
    }
  });
  test(
    'slot choices, non-interactive nesting and contextual editors agree',
    () {
      for (final slot in [
        'dialog',
        'menu',
        'icon',
        'trigger',
        'title',
        'action',
        'content',
      ]) {
        for (final type in slotTypes(slot))
          validateConfig(
            switchComponent({}, type, slot: slot),
            'slot:$slot',
            slot,
          );
      }
      final s = initialScene();
      expect(typesAt(s, ['modules', 4, 'props', 'builder']), ['GlassDialog']);
      expect(typesAt(s, ['modules', 3, 'props', 'items', 0]), [
        'MenuItemButton',
      ]);
      expect(typesAt(s, ['modules', 2, 'props', 'decoration', 'prefixIcon']), [
        'Icon',
      ]);
      expect(
        () => validateConfig({'type': 'GlassPageRoute'}, 'slot:dialog', '目标内容'),
        throwsFormatException,
      );
      expect(
        () => validateConfig(
          {
            'type': 'Row',
            'children': [
              {'type': 'GlassButton'},
            ],
          },
          'slot:trigger',
          '触发器',
        ),
        throwsFormatException,
      );
      expect(fieldLabel('textStyle', 'height'), '行高倍数');
      expect(fieldLabel('gradient', 'type'), '渐变类型');
    },
  );
  test(
    'all supported configuration schemas and options have Chinese labels',
    () {
      final kinds = [
        'theme',
        'layout',
        'performance',
        'accessibility',
        'motion',
        'dialogMotion',
        'material',
        'control',
        'customControl',
        'textStyle',
        'paint',
        'side',
        'constraints',
        'gradient',
        'scheme',
        'textTheme',
        'route',
        'decoration',
        'inputBorder',
        'binding',
        'action',
        for (final type in componentDefaults.keys) 'component:$type',
      ];
      final missing = <String>{};
      for (final kind in kinds) {
        for (final entry in schemaFor(kind).entries) {
          if (!RegExp(r'[\u4e00-\u9fff]').hasMatch(fieldLabel(kind, entry.key)))
            missing.add(entry.key);
          final base = entry.value.replaceFirst('state:', '');
          if (base.startsWith('enum:') && base != 'enum:component') {
            for (final option in enumValues(base.substring(5))!) {
              if (!RegExp(r'[\u4e00-\u9fff]').hasMatch(chineseLabel(option)))
                missing.add(option);
            }
          }
        }
      }
      expect(missing, isEmpty);
    },
  );
  test(
    'invalid parameters are rejected, old inactive data is retained unchanged',
    () {
      for (final pair in [
        [
          'material',
          {'tintOpacity': 2},
        ],
        [
          'material',
          {'shape': 'stadium'},
        ],
        [
          'textStyle',
          {'fontWeight': 'unknown'},
        ],
        [
          'constraints',
          {'minWidth': 300, 'maxWidth': 100},
        ],
        [
          'customControl',
          {
            'fixedSize': [80, 40],
          },
        ],
        [
          'control',
          {'shape': 'rectangle'},
        ],
        [
          'gradient',
          {
            'colors': ['#ffffff'],
          },
        ],
        [
          'gradient',
          {
            'colors': ['#ffffff', '#000000'],
            'stops': [1, 0],
          },
        ],
        [
          'action',
          {'action': 'setText'},
        ],
        [
          'slot:root',
          {'type': 'Text', 'maxLines': 1.5},
        ],
        [
          'slot:root',
          {'type': 'GlassBackdrop', 'intensity': 2},
        ],
      ]) {
        expect(
          () => validateConfig(pair[1], pair[0] as String, '错误参数'),
          throwsFormatException,
        );
      }
      final old = initialScene();
      old['modules'][0]['props']['retiredOption'] = {'用户数据': '保留'};
      validateScene(old, legacy: true);
      final next = clone(old);
      next['modules'][0]['w'] = 440;
      validateScene(next, previous: old);
      next['modules'][0]['props']['retiredOption'] = '改变无效字段';
      expect(() => validateScene(next, previous: old), throwsFormatException);
      final encoded = jsonEncode(old);
      prepareScene(old);
      expect(jsonEncode(old), encoded);
    },
  );

  test(
    'Chinese bindings and incompatible variable values have safe results',
    () {
      final runtime = Runtime(() {}, (_) {});
      runtime.values['计数'] = 3;
      expect(runtime.interpolate('累计 {{ 计数 }} 次'), '累计 3 次');
      expect(runtime.resolve({'bind': '计数', 'default': false}), false);
      runtime.dispose();
    },
  );

  testWidgets(
    'dialog barrier policy and repeated open/close preserve the parent',
    (tester) async {
      final runtime = Runtime(() {}, (_) {});
      for (final dismissible in [true, false]) {
        await mount(tester, runtime, {
          'type': 'showGlassDialog',
          ...clone(componentDefaults['showGlassDialog']!),
          'barrierDismissible': dismissible,
        });
        await tester.tap(find.text('打开玻璃弹窗'));
        await tester.pumpAndSettle();
        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();
        expect(
          find.text('你好，玻璃世界'),
          dismissible ? findsNothing : findsOneWidget,
        );
        if (!dismissible) {
          await tester.tap(find.text('关闭'));
          await tester.pumpAndSettle();
        }
        expect(find.text('打开玻璃弹窗'), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      runtime.dispose();
    },
  );

  testWidgets(
    'running backdrop stops when reduced motion changes; overlap disables grouping',
    (tester) async {
      final runtime = Runtime(() {}, (_) {});
      await mount(tester, runtime, {'type': 'GlassBackdrop', 'animate': true});
      expect(tester.binding.hasScheduledFrame, isTrue);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
      for (final overlapping in [false, true]) {
        await mount(tester, runtime, {
          'type': 'GlassGroup',
          'overlapping': overlapping,
          'child': {'type': 'GlassSurface', 'width': 100, 'height': 100},
        });
        final filters = tester.widgetList<BackdropFilter>(
          find.byType(BackdropFilter),
        );
        expect(filters, isNotEmpty);
        final rendered = tester.renderObject<RenderBackdropFilter>(
          find.byType(BackdropFilter).first,
        );
        expect(rendered.backdropKey != null, !overlapping);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      runtime.dispose();
    },
  );

  for (final type in componentDefaults.keys) {
    testWidgets(
      'C/$type: every exposed top-level parameter mounts with its typed value',
      (tester) async {
        final runtime = Runtime(() {}, (_) {});
        final node = {'type': type, ...clone(componentDefaults[type]!)};
        for (final entry in schemaFor('component:$type').entries) {
          if (['type', '_nodeId'].contains(entry.key)) continue;
          final changed = clone(node);
          dynamic value = sample(entry.value);
          if (entry.key == 'intensity') value = .5;
          if (entry.key == 'toolbarHeight') value = 64;
          if (entry.key == 'bottomHeight') changed['bottom'] = textNode('底部内容');
          if (entry.key == 'maxLines') value = 2;
          if (entry.key == 'spacing' || entry.key == 'indent') value = 8;
          changed[entry.key] = value;
          validateConfig(changed, 'slot:root', '$type.${entry.key}');
          await mount(tester, runtime, changed);
          expect(tester.takeException(), isNull, reason: '$type.${entry.key}');
          await tester.pumpWidget(const SizedBox());
          await tester.pump();
        }
        runtime.dispose();
      },
    );
  }

  testWidgets(
    'module dimensions apply on blur, reject errors, undo; inner size is visible',
    (tester) async {
      tester.view.physicalSize = const Size(1500, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const GlassLab(initialAdvanced: true));
      await tester.pumpAndSettle();
      final state = tester.state(find.byType(GlassLab)) as dynamic;
      final input = find.byKey(const ValueKey('modules.0.w'));
      await tester.enterText(input, '440');
      await tester.pumpAndSettle();
      await tester.tap(find.text('画布布局'));
      await tester.pumpAndSettle();
      expect(state.scene['modules'][0]['w'], 440);
      expect(tester.getSize(find.byKey(const ValueKey('node-1'))).width, 440);
      await tester.tap(find.byTooltip('撤销'));
      await tester.pumpAndSettle();
      expect(state.scene['modules'][0]['w'], 360);
      await tester.enterText(input, '-1');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(state.scene['modules'][0]['w'], 360);
      expect(find.textContaining('应在'), findsOneWidget);
      await tester.enterText(input, '360');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(state.editPath(['modules', 0, 'type'], 'GlassSurface'), isNull);
      await tester.pumpAndSettle();
      expect(state.editPath(['modules', 0, 'props', 'width'], 120), isNull);
      expect(state.editPath(['modules', 0, 'props', 'height'], 90), isNull);
      await tester.pumpAndSettle();
      final surface = find
          .descendant(
            of: find.byKey(const ValueKey('node-1/root')),
            matching: find.byType(GlassSurface),
          )
          .first;
      expect(tester.getSize(surface), const Size(120, 90));
      expect(
        tester.getSize(find.byKey(const ValueKey('node-1'))),
        const Size(360, 220),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'type replacement rebuilds fields and undo restores the complete node',
    (tester) async {
      tester.view.physicalSize = const Size(1500, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const GlassLab(initialAdvanced: true));
      await tester.pumpAndSettle();
      final state = tester.state(find.byType(GlassLab)) as dynamic;
      final original = jsonEncode(state.scene['modules'][0]);
      final type = find.byKey(const ValueKey('[modules, 0, type]/GlassCard'));
      await tester.ensureVisible(type);
      await tester.tap(type);
      await tester.pumpAndSettle();
      await tester.tap(find.text('玻璃表面').last);
      await tester.pumpAndSettle();
      expect(state.scene['modules'][0]['type'], 'GlassSurface');
      expect(
        (state.scene['modules'][0]['props'] as Map).containsKey('onTap'),
        isFalse,
      );
      expect(
        (state.scene['modules'][0]['props'] as Map).containsKey('width'),
        isTrue,
      );
      await tester.tap(find.byTooltip('撤销'));
      await tester.pumpAndSettle();
      expect(jsonEncode(state.scene['modules'][0]), original);
      await tester.tap(find.byTooltip('重做'));
      await tester.pumpAndSettle();
      expect(state.scene['modules'][0]['type'], 'GlassSurface');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'buttons/card/icon: pointer, keyboard, disabled and callback actions',
    (tester) async {
      final log = <String>[];
      final runtime = Runtime(() {}, log.add);
      for (final type in ['GlassButton', 'GlassCard', 'GlassIconButton']) {
        final spec = {'type': type, ...clone(componentDefaults[type]!)};
        final callback = type == 'GlassCard' ? 'onTap' : 'onPressed';
        spec[callback] = {'action': 'increment', 'key': 'calls'};
        spec['autofocus'] = true;
        await mount(tester, runtime, spec);
        final target = type == 'GlassIconButton'
            ? find.byIcon(Icons.favorite_outline)
            : find.text(type == 'GlassCard' ? '把灵感放进玻璃里' : '试试点击我');
        final before = runtime.values['calls'] ?? 0;
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(runtime.values['calls'], before + 1);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(runtime.values['calls'], before + 2);
        spec[callback] = 'none';
        await mount(tester, runtime, spec);
        await tester.tap(target);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(runtime.values['calls'], before + 2);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      }
      runtime.dispose();
    },
  );

  testWidgets(
    'input: draft, submit, read-only, disabled, setText and focus targets',
    (tester) async {
      final log = <String>[];
      final runtime = Runtime(() {}, log.add);
      final spec = {
        'type': 'GlassTextField',
        ...clone(componentDefaults['GlassTextField']!),
        'controller': 'editor',
        'focusNode': 'editor-focus',
        'text': '初始中文',
      };
      await mount(tester, runtime, spec);
      await tester.enterText(find.byType(TextField), '编辑中的中文');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(log.any((s) => s.contains('输入提交：编辑中的中文')), isTrue);
      await mount(tester, runtime, spec);
      expect(runtime.controllers['editor']!.text, '编辑中的中文');
      final context = tester.element(find.byType(TextField));
      runtime.action(
        {'action': 'setText', 'target': 'editor', 'text': '动作设置'},
        context,
        'probe',
      )!();
      await tester.pump();
      expect(runtime.controllers['editor']!.text, '动作设置');
      runtime.action(
        {'action': 'focus', 'target': 'editor-focus'},
        context,
        'probe',
      )!();
      await tester.pump();
      expect(runtime.focuses['editor-focus']!.hasFocus, isTrue);
      spec['readOnly'] = true;
      await mount(tester, runtime, spec);
      expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
      spec['enabled'] = false;
      await mount(tester, runtime, spec);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      runtime.action(
        {'action': 'focus', 'target': 'missing'},
        tester.element(find.byType(TextField)),
        'probe',
      )!();
      expect(log.last, contains('不存在'));
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(runtime.controllers, isEmpty);
      expect(runtime.focuses, isEmpty);
      runtime.dispose();
    },
  );

  testWidgets(
    'navigation/tab: controlled selection and independent close callback',
    (tester) async {
      StateSetter? update;
      final runtime = Runtime(() => update?.call(() {}), (_) {});
      for (final type in ['GlassNavigationItem', 'GlassTab']) {
        final spec = {
          'type': type,
          ...clone(componentDefaults[type]!),
          'selected': {'bind': 'selection', 'default': false},
        };
        spec[type == 'GlassTab' ? 'onSelected' : 'onPressed'] = {
          'action': 'toggle',
          'key': 'selection',
        };
        if (type == 'GlassTab')
          spec['onClose'] = {'action': 'increment', 'key': 'closed'};
        runtime.values['selection'] = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (c, set) {
                  update = set;
                  return Center(
                    child: SizedBox(
                      width: 300,
                      child: runtime.build(spec, c, 'probe'),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(spec['label'] as String));
        await tester.pumpAndSettle();
        expect(runtime.values['selection'], true);
        if (type == 'GlassTab') {
          await tester.tap(find.byIcon(Icons.close));
          await tester.pumpAndSettle();
          expect(runtime.values['closed'], 1);
          expect(runtime.values['selection'], true);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      }
      runtime.dispose();
    },
  );

  testWidgets(
    'menu item: keep-open, disabled, Escape, dialog and page actions',
    (tester) async {
      final events = <String>[];
      final runtime = Runtime(() {}, events.add);
      Future<void> menu(dynamic action, {bool close = true}) =>
          mount(tester, runtime, {
            'type': 'GlassMenu',
            'trigger': textNode('测试菜单'),
            'items': [
              {
                'type': 'MenuItemButton',
                'child': textNode('执行菜单项'),
                'onPressed': action,
                'closeOnActivate': close,
              },
            ],
          });
      await menu('log', close: false);
      await tester.tap(find.text('测试菜单'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('执行菜单项'));
      await tester.pumpAndSettle();
      expect(find.text('执行菜单项'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('执行菜单项'), findsNothing);
      await menu('none');
      await tester.tap(find.text('测试菜单'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<MenuItemButton>(find.byType(MenuItemButton)).onPressed,
        isNull,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      for (final action in ['dialog', 'route']) {
        await menu(action);
        await tester.tap(find.text('测试菜单'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('执行菜单项'));
        await tester.pumpAndSettle();
        if (action == 'dialog') {
          expect(find.byType(GlassDialog), findsOneWidget);
          await tester.tap(find.text('知道了'));
        } else {
          expect(find.text('测试路由'), findsOneWidget);
          expect(find.text('把灵感放进玻璃里'), findsOneWidget);
          await tester.pageBack();
        }
        await tester.pumpAndSettle();
        expect(find.text('测试菜单'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      runtime.dispose();
    },
  );

  testWidgets(
    'explicit dialog/page triggers: target, return, barrier and reduced motion',
    (tester) async {
      final runtime = Runtime(() {}, (_) {});
      for (final type in ['showGlassDialog', 'GlassPageRoute']) {
        final spec = {
          'type': type,
          ...clone(componentDefaults[type]!),
          'motion': {'transition': 'none', 'duration': 0},
        };
        await mount(tester, runtime, spec);
        await tester.tap(
          find.text(type == 'showGlassDialog' ? '打开玻璃弹窗' : '打开示例页面'),
        );
        await tester.pumpAndSettle();
        if (type == 'showGlassDialog') {
          expect(find.text('你好，玻璃世界'), findsOneWidget);
          await tester.tap(find.text('关闭'));
        } else {
          expect(find.text('新的页面，新的可能。'), findsOneWidget);
          await tester.pageBack();
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      }
      runtime.dispose();
    },
  );

  testWidgets(
    'reorder and type removal retain drafts by node identity and release unused resources',
    (tester) async {
      final runtime = Runtime(() {}, (_) {});
      final scene = initialScene();
      scene['modules'] = [
        module('Column', 1)
          ..['props'] = {
            'children': [
              {'type': 'GlassTextField', 'text': '第一项'},
              {'type': 'GlassTextField', 'text': '第二项'},
            ],
          },
      ];
      final prepared = prepareScene(scene);
      final children = prepared['modules'][0]['props']['children'] as List;
      var spec = <String, dynamic>{'type': 'Column', 'children': children};
      await mount(tester, runtime, spec);
      await tester.enterText(find.byType(TextField).first, '第一项草稿');
      await tester.pump();
      await tester.enterText(find.byType(TextField).last, '第二项草稿');
      await tester.pump();
      spec = {'type': 'Column', 'children': children.reversed.toList()};
      await mount(tester, runtime, spec);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '第二项草稿',
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        '第一项草稿',
      );
      expect(runtime.controllers.length, 2);
      spec = {
        'type': 'Column',
        'children': [children.first],
      };
      await mount(tester, runtime, spec);
      await tester.pump();
      expect(runtime.controllers.length, 1);
      expect(runtime.focuses.length, 1);
      await mount(tester, runtime, {'type': 'Text', 'text': '已替换'});
      await tester.pump();
      expect(runtime.controllers, isEmpty);
      expect(runtime.focuses, isEmpty);
      await tester.pumpWidget(const SizedBox());
      runtime.dispose();
    },
  );

  testWidgets(
    'surface settings, row/column alignment, toolbar and app-bar geometry are observable',
    (tester) async {
      final runtime = Runtime(() {}, (_) {});
      await mount(tester, runtime, {
        'type': 'GlassSurface',
        'width': 210,
        'height': 120,
        'padding': 8,
        'alignment': 'bottomRight',
        'style': {'tintOpacity': .6, 'borderWidth': 3},
      });
      expect(tester.getSize(find.byType(GlassSurface)), const Size(210, 120));
      final surface = tester.widget<GlassSurface>(find.byType(GlassSurface));
      expect(surface.padding, const EdgeInsets.all(8));
      expect(surface.alignment, Alignment.bottomRight);
      expect(surface.style!.tintOpacity, .6);
      final row = {
        'type': 'Row',
        'children': [textNode('甲'), textNode('乙')],
        'alignment': 'start',
        'spacing': 8,
      };
      await mount(tester, runtime, row, width: 300, height: 160);
      final start = tester.getTopLeft(find.text('甲')).dx;
      row['alignment'] = 'end';
      await mount(tester, runtime, row, width: 300, height: 160);
      expect(tester.getTopLeft(find.text('甲')).dx, greaterThan(start + 100));
      final column = {
        'type': 'Column',
        'children': [textNode('上'), textNode('下')],
        'alignment': 'start',
      };
      await mount(tester, runtime, column, width: 300, height: 160);
      final top = tester.getTopLeft(find.text('上')).dy;
      column['alignment'] = 'end';
      await mount(tester, runtime, column, width: 300, height: 160);
      expect(tester.getTopLeft(find.text('上')).dy, greaterThan(top + 60));
      await mount(tester, runtime, {
        'type': 'GlassAppBar',
        'toolbarHeight': 72,
        'bottom': textNode('底部'),
        'bottomHeight': 32,
      });
      expect(tester.getSize(find.byType(GlassAppBar)).height, 104);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      runtime.dispose();
    },
  );

  testWidgets('button colors resolve hover, press, focus and disabled states', (
    tester,
  ) async {
    final runtime = Runtime(() {}, (_) {});
    final spec = {
      'type': 'GlassButton',
      'child': textNode('状态按钮'),
      'onPressed': 'log',
      'controlStyle': {
        'foregroundColor': {
          'default': '#FF0000',
          'hovered': '#00FF00',
          'pressed': '#0000FF',
          'focused': '#FFFF00',
          'disabled': '#888888',
        },
      },
    };
    await mount(tester, runtime, spec);
    Color? foreground() =>
        DefaultTextStyle.of(tester.element(find.text('状态按钮'))).style.color;
    expect(foreground(), const Color(0xFFFF0000));
    final mouse = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('状态按钮')));
    await tester.pumpAndSettle();
    expect(foreground(), const Color(0xFF00FF00));
    await mouse.down(tester.getCenter(find.text('状态按钮')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(foreground(), const Color(0xFF0000FF));
    await mouse.up();
    await tester.pumpAndSettle();
    final ink = find.byType(InkWell).first;
    tester.widget<InkWell>(ink).onFocusChange?.call(true);
    await tester.pumpAndSettle();
    expect(foreground(), const Color(0xFFFFFF00));
    spec['onPressed'] = 'none';
    await mount(tester, runtime, spec);
    expect(foreground(), const Color(0xFF888888));
    await mouse.removePointer();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    runtime.dispose();
  });

  testWidgets(
    'global inheritance, high contrast, low quality and dynamic reduce-motion stay effective',
    (tester) async {
      tester.view.physicalSize = const Size(1500, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(
            highContrast: true,
            disableAnimations: true,
          );
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(const GlassLab(initialAdvanced: true));
      await tester.pumpAndSettle();
      final state = tester.state(find.byType(GlassLab)) as dynamic;
      final scene = initialScene();
      scene['theme']['layout']['cardPadding'] = 34;
      scene['theme']['performance']['quality'] = 'low';
      scene['modules'] = [
        module('GlassCard', 1)
          ..['props'] = {
            'child': {
              'type': 'Text',
              'text': '对比度',
              'style': {'color': '#FFFFFF'},
            },
          },
      ];
      expect(state.commit(scene), isNull);
      await tester.pumpAndSettle();
      final card = tester.widget<GlassCard>(find.byType(GlassCard));
      expect(card.padding, const EdgeInsets.all(20));
      // The compatibility getter stays 20; build resolves the explicitly changed theme to 34.
      final padding = find.descendant(
        of: find.byType(GlassCard),
        matching: find.byWidgetPredicate(
          (w) => w is Padding && w.padding == const EdgeInsets.all(34),
        ),
      );
      expect(padding, findsWidgets);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(
        MediaQuery.of(tester.element(find.text('对比度'))).highContrast,
        isTrue,
      );
      expect(
        tester.widget<Text>(find.text('对比度')).style!.color,
        const Color(0xff17233b),
      );
      await tester.pumpWidget(const SizedBox());
      final runtime = Runtime(() {}, (_) {});
      await mount(tester, runtime, {'type': 'GlassBackdrop', 'animate': true});
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      runtime.dispose();
    },
  );

  testWidgets(
    'nested dialog, icon and shape editors use actual allowed options at 200 percent',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        const RepaintBoundary(
          key: ValueKey('capture'),
          child: GlassLab(initialAdvanced: true),
        ),
      );
      await tester.pumpAndSettle();
      final state = tester.state(find.byType(GlassLab)) as dynamic;
      final scene = initialScene();
      scene['modules'] = [module('showGlassDialog', 1, x: 0, y: 0)];
      expect(state.commit(scene), isNull);
      await tester.pumpAndSettle();
      state.showInspector(tester.element(find.byType(Scaffold).first));
      await tester.pumpAndSettle();
      final scrollable = find
          .descendant(
            of: find.byKey(const ValueKey('properties')),
            matching: find.byType(Scrollable),
          )
          .first;
      Future<void> reveal(Finder target) async {
        if (target.evaluate().isEmpty)
          await tester.scrollUntilVisible(
            target,
            200,
            scrollable: scrollable,
            maxScrolls: 60,
          );
        await Scrollable.ensureVisible(tester.element(target), alignment: .5);
        await tester.pumpAndSettle();
      }

      final builder = find.byKey(
        const ValueKey('section-modules.0.props.builder'),
      );
      await reveal(builder);
      await tester.tap(
        find.descendant(of: builder, matching: find.text('目标内容')).first,
      );
      await tester.pumpAndSettle();
      final selector = find.byKey(
        const ValueKey('[modules, 0, props, builder, type]/GlassDialog'),
      );
      await reveal(selector);
      expect(
        tester.widget<DropdownButtonFormField<String>>(selector).onChanged,
        isNull,
      );
      final button = tester.widget<DropdownButton<String>>(
        find.descendant(
          of: selector,
          matching: find.byType(DropdownButton<String>),
        ),
      );
      expect(button.items!.map((v) => v.value).toList(), ['GlassDialog']);
      await screenshot(tester, 'nested-dialog-selector-320-2.0');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  test(
    'round-trip retains values and node identity; invalid frames/focus are rejected',
    () {
      final s = prepareScene(initialScene());
      final encoded = jsonEncode(s);
      final read = jsonDecode(encoded) as Json;
      validateScene(read);
      expect(jsonEncode(prepareScene(read)), encoded);
      final invalid = initialScene();
      invalid['modules'] = [
        module('GlassSurface', 1)..['props']['width'] = 500,
      ];
      expect(() => validateScene(invalid), throwsFormatException);
      final focus = initialScene();
      focus['modules'] = [
        module('GlassTextField', 1),
        module('GlassTextField', 2),
      ];
      for (final node in focus['modules']) {
        node['props']['focusNode'] = 'shared';
      }
      expect(() => validateScene(focus), throwsFormatException);
      expect(
        textStyle({'fontStyle': 'normal', 'decoration': 'none'})!.fontStyle,
        FontStyle.normal,
      );
      expect(
        textStyle({'decoration': 'none'})!.decoration,
        TextDecoration.none,
      );
    },
  );

  for (final type in componentDefaults.keys) {
    testWidgets(
      'Chinese layout/$type: five widths, three font scales, inspector',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        for (final width in [320.0, 390.0, 820.0, 1180.0, 1500.0]) {
          for (final scale in [1.0, 1.3, 2.0]) {
            tester.view.physicalSize = Size(width, 1000);
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            await tester.pumpWidget(
              const RepaintBoundary(
                key: ValueKey('capture'),
                child: GlassLab(initialAdvanced: true),
              ),
            );
            await tester.pumpAndSettle();
            final state = tester.state(find.byType(GlassLab)) as dynamic;
            final scene = initialScene();
            final item = module(type, 1, x: 0, y: 0)
              ..['w'] = 250
              ..['h'] = 600;
            scene['modules'] = [item];
            expect(state.commit(scene), isNull);
            await tester.pumpAndSettle();
            if (width < 1180) {
              state.showInspector(tester.element(find.byType(Scaffold).first));
              await tester.pumpAndSettle();
            }
            expect(
              tester.takeException(),
              isNull,
              reason: '$type/$width/$scale',
            );
            expect(
              find.text('编号'),
              findsNothing,
              reason: 'layout fields must not invent empty module metadata',
            );
            for (final input in tester.widgetList<ParameterInput>(
              find.byType(ParameterInput),
            )) {
              final key = (input.key as ValueKey).value as String;
              final path = key
                  .split('.')
                  .map<dynamic>((p) => int.tryParse(p) ?? p)
                  .toList();
              expect(
                input.value,
                valueAt(state.scene as Json, path),
                reason: '$type/$key must reflect the saved value',
              );
            }
            if ((width == 320 && scale == 2) || (width == 1500 && scale == 1))
              await screenshot(tester, '$type-${width.toInt()}-$scale');
            await tester.pumpWidget(const SizedBox());
            await tester.pump();
          }
        }
      },
    );
  }
}
