import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

void main() {
  testWidgets(
    'dialog captures merged geometry, closes with Esc and restores focus',
    (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiquidGlassTheme.merge(
              data: (parent) => parent.copyWith(
                layout: parent.layout.copyWith(
                  dialogPadding: const EdgeInsets.all(9),
                  dialogMaxWidth: 300,
                ),
              ),
              child: Builder(
                builder: (context) => GlassButton(
                  focusNode: focus,
                  onPressed: () => showGlassDialog<void>(
                    context: context,
                    builder: (context) => const GlassDialog(
                      title: Text('Title'),
                      content: Text('Content'),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      focus.requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(GlassDialog), findsOneWidget);
      final context = tester.element(find.byType(GlassDialog));
      expect(LiquidGlassTheme.of(context).layout.dialogMaxWidth, 300);
      final surface = tester.widget<GlassSurface>(
        find.descendant(
          of: find.byType(GlassDialog),
          matching: find.byType(GlassSurface),
        ),
      );
      expect(surface.padding, const EdgeInsets.all(9));
      expect(surface.constraints!.maxWidth, 300);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(GlassDialog), findsNothing);
      expect(focus.hasFocus, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'non-dismissible dialog rejects Esc and returns an explicit result',
    (tester) async {
      String? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => GlassButton(
                onPressed: () async {
                  result = await showGlassDialog<String>(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => GlassDialog(
                      content: const Text('Required'),
                      actions: [
                        GlassButton(
                          onPressed: () => Navigator.pop(context, 'done'),
                          child: const Text('Confirm'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(GlassDialog), findsOneWidget);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(result, 'done');
    },
  );

  testWidgets(
    'card and icon focus nodes remain owned and usable by their caller',
    (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      var taps = 0;
      Widget scene(Widget control) => MaterialApp(
        home: Scaffold(body: Center(child: control)),
      );
      await tester.pumpWidget(
        scene(
          GlassCard(
            focusNode: node,
            onTap: () => taps++,
            child: const Text('Card'),
          ),
        ),
      );
      node.requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(taps, 1);
      await tester.pumpWidget(scene(const SizedBox.shrink()));
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        scene(
          GlassIconButton(
            focusNode: node,
            onPressed: () => taps++,
            tooltip: 'Reuse',
            controlStyle: const ButtonStyle(
              side: WidgetStatePropertyAll(BorderSide.none),
            ),
            icon: const Icon(Icons.add),
          ),
        ),
      );
      node.requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(taps, 2);
      expect(node.hasFocus, isTrue);
      final focusedStyle = tester
          .widget<GlassSurface>(find.byType(GlassSurface))
          .style!;
      expect(focusedStyle.borderWidth, greaterThanOrEqualTo(2));
      expect(focusedStyle.borderColor.a, greaterThan(0));
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets(
    'local dark semantics reach cards and dialogs inside a light app',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiquidGlassTheme(
              data: LiquidGlassThemeData.dark(),
              child: const Column(
                children: [
                  GlassCard(child: Text('Card text')),
                  GlassDialog(content: Text('Dialog text')),
                ],
              ),
            ),
          ),
        ),
      );
      for (final label in ['Card text', 'Dialog text']) {
        expect(
          DefaultTextStyle.of(tester.element(find.text(label))).style.color,
          Colors.white,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('dialog stays scrollable on a narrow window with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiquidGlassTheme.merge(
            data: (parent) =>
                parent.copyWith(visualDensity: VisualDensity.compact),
            child: GlassDialog(
              title: const Text('学习资料 Materials'),
              content: Text(List.filled(20, '中英文内容 content').join('\n')),
              actions: [
                GlassButton(onPressed: () {}, child: const Text('确定 Confirm')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
