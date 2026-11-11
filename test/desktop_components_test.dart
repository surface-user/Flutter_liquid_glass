import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';
import '../example/integration_test/fixtures/desktop_consumer.dart';

Widget host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets(
    'tree indentation moves from the leading edge in both directions',
    (tester) async {
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          host(
            Directionality(
              textDirection: direction,
              child: const SizedBox(
                width: 240,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GlassNavigationItem(
                      label: 'Parent',
                      leading: Icon(Icons.folder_outlined),
                    ),
                    GlassNavigationItem(
                      label: 'Child',
                      indent: 12,
                      leading: Icon(Icons.folder_outlined),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        final parent = tester.getRect(find.text('Parent'));
        final child = tester.getRect(find.text('Child'));
        expect(
          direction == TextDirection.ltr
              ? child.left - parent.left
              : parent.right - child.right,
          closeTo(12, .001),
        );
      }
    },
  );
  testWidgets(
    'input retains composition, selection and external ownership across rebuilds',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      var clipboard = '';
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          switch (call.method) {
            case 'Clipboard.setData':
              clipboard = (call.arguments as Map)['text'] as String;
              return null;
            case 'Clipboard.getData':
              return {'text': clipboard};
            case 'Clipboard.hasStrings':
              return {'value': clipboard.isNotEmpty};
            default:
              return null;
          }
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final controller = TextEditingController();
      final focus = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      late StateSetter rebuild;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return GlassTextField(
                controller: controller,
                focusNode: focus,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  errorText: 'Test error',
                ),
              );
            },
          ),
        ),
      );
      await tester.tap(find.byType(TextField));
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'ni',
          selection: TextSelection.collapsed(offset: 2),
          composing: TextRange(start: 0, end: 2),
        ),
      );
      await tester.pump();
      rebuild(() {});
      await tester.pump();
      expect(controller.value.composing, const TextRange(start: 0, end: 2));
      expect(focus.hasFocus, isTrue);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '你好',
          selection: TextSelection(baseOffset: 0, extentOffset: 1),
        ),
      );
      await tester.pump();
      await Clipboard.setData(const ClipboardData(text: '资料'));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(controller.text, '资料好');
      await tester.pumpWidget(const SizedBox.shrink());
      controller.text = 'Still owned';
      focus.requestFocus();
      expect(controller.text, 'Still owned');
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets(
    'implicit input draft survives parent rebuild and read-only rejects editing',
    (tester) async {
      late StateSetter rebuild;
      var readOnly = false;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return GlassTextField(readOnly: readOnly);
            },
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Draft');
      final controller = tester
          .widget<EditableText>(find.byType(EditableText))
          .controller;
      rebuild(() => readOnly = true);
      await tester.pumpAndSettle();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller,
        same(controller),
      );
      expect(controller.text, 'Draft');
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(text: 'Blocked'),
      );
      await tester.pump();
      expect(controller.text, 'Draft');
    },
  );

  testWidgets(
    'disabled input cannot focus and high contrast overrides decorative hints',
    (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        host(
          LiquidGlassTheme(
            data: const LiquidGlassThemeData(
              accessibility: GlassAccessibilityConfig(highContrast: true),
            ),
            child: GlassTextField(
              focusNode: focus,
              enabled: false,
              decoration: const InputDecoration(
                hintText: 'Visible hint',
                hintStyle: TextStyle(color: Colors.white),
                fillColor: Colors.black,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(TextField), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(focus.hasFocus, isFalse);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration!.hintStyle!.color, const Color(0xff17233b));
      expect(field.decoration!.fillColor, const Color(0xffedf1f8));
    },
  );

  testWidgets(
    'navigation keyboard activation is controlled and close does not select',
    (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      var selected = 0, closed = 0;
      await tester.pumpWidget(
        host(
          GlassTab(
            label: 'Tab',
            selected: true,
            focusNode: focus,
            onSelected: () => selected++,
            onClose: () => closed++,
          ),
        ),
      );
      focus.requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(selected, 1);
      final inherited = Theme.of(
        tester.element(find.text('Tab')),
      ).textTheme.labelLarge!;
      final actual = DefaultTextStyle.of(
        tester.element(find.text('Tab')),
      ).style;
      expect(actual.fontFamily, inherited.fontFamily);
      expect(actual.fontSize, inherited.fontSize);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(closed, 1);
      expect(selected, 1);
      expect(find.byType(BackdropFilter), findsNothing);
      await tester.pumpWidget(
        host(const GlassNavigationItem(label: 'Disabled')),
      );
      await tester.tap(find.text('Disabled'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(selected, 1);
    },
  );

  testWidgets(
    'menu keyboard close restores focus and action closes exactly once',
    (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      var opens = 0, closes = 0, actions = 0;
      await tester.pumpWidget(
        host(
          GlassMenu(
            focusNode: focus,
            trigger: const Text('Menu'),
            onOpen: () => opens++,
            onClose: () => closes++,
            items: [
              MenuItemButton(
                onPressed: () => actions++,
                child: const Text('Action'),
              ),
            ],
          ),
        ),
      );
      focus.requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Action'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Action'), findsNothing);
      expect(focus.hasFocus, isTrue);
      expect(closes, 1);
      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Action'));
      await tester.pumpAndSettle();
      expect(actions, 1);
      expect(opens, 2);
      expect(closes, 2);
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'disabling an open menu closes it once and keeps external focus usable',
    (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      late StateSetter rebuild;
      var enabled = true, closes = 0;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return GlassMenu(
                focusNode: focus,
                trigger: const Text('Menu'),
                enabled: enabled,
                onClose: () => closes++,
                items: [
                  MenuItemButton(onPressed: () {}, child: const Text('Action')),
                ],
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();
      rebuild(() => enabled = false);
      await tester.pumpAndSettle();
      expect(find.text('Action'), findsNothing);
      expect(closes, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      focus.requestFocus();
    },
  );

  testWidgets('menu stays inside a narrow bottom-right window boundary', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 240);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomRight,
            child: GlassMenu(
              trigger: const Text('Menu'),
              items: [
                MenuItemButton(
                  onPressed: () {},
                  child: const Text('First item'),
                ),
                MenuItemButton(
                  onPressed: () {},
                  child: const Text('Second item'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    for (final label in ['First item', 'Second item']) {
      final rect = tester.getRect(find.text(label));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(320));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(240));
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('SDK feedback composition stops ticking when loading finishes', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const Tooltip(message: 'Working', child: CircularProgressIndicator()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpWidget(host(const Text('No items')));
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    expect(find.text('No items'), findsOneWidget);
  });

  testWidgets('desktop consumer supports narrow windows and 2x text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const DesktopConsumer());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '中英文资料 Learning materials');
    await tester.tap(find.byKey(const ValueKey('nav-b')));
    await tester.pumpAndSettle();
    expect(find.text('Selection: B'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    for (final compact in [false, true]) {
      for (final mode in [
        'normal',
        'no_blur',
        'reduce_motion',
        'high_contrast',
      ]) {
        testWidgets(
          'public desktop consumer / ${brightness.name} / $compact / $mode',
          (tester) async {
            await tester.pumpWidget(
              DesktopConsumer(
                brightness: brightness,
                compact: compact,
                noBlur: mode == 'no_blur',
                reduceMotion: mode == 'reduce_motion',
                highContrast: mode == 'high_contrast',
              ),
            );
            await tester.pumpAndSettle();
            await tester.enterText(find.byType(TextField), 'Draft');
            await tester.tap(find.byKey(const ValueKey('nav-b')));
            await tester.pumpAndSettle();
            expect(find.text('Selection: B'), findsOneWidget);
            expect(find.text('Draft: Draft'), findsOneWidget);
            await tester.tap(find.text('Actions'));
            await tester.pumpAndSettle();
            expect(find.text('Open dialog'), findsOneWidget);
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            await tester.pumpAndSettle();
            if (mode == 'no_blur' || mode == 'high_contrast')
              expect(find.byType(BackdropFilter), findsNothing);
            expect(tester.binding.transientCallbackCount, 0);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
