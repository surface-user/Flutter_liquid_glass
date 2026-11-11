import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ThemeData(platform: TargetPlatform.windows),
  home: Scaffold(body: Center(child: child)),
);

FocusNode _triggerFocus(WidgetTester tester, String label) => tester
    .widget<TextButton>(
      find
          .ancestor(of: find.text(label), matching: find.byType(TextButton))
          .first,
    )
    .focusNode!;

Future<void> _key(
  WidgetTester tester,
  LogicalKeyboardKey logical,
  PhysicalKeyboardKey physical,
) async {
  await tester.sendKeyEvent(logical, physicalKey: physical);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'open menu transfers trigger focus across external and implicit owners',
    (tester) async {
      final first = FocusNode(), second = FocusNode();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      FocusNode? owner = first;
      late StateSetter rebuild;
      var opens = 0, closes = 0;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return GlassMenu(
                trigger: const Text('Owner menu'),
                focusNode: owner,
                onOpen: () => opens++,
                onClose: () => closes++,
                items: [
                  MenuItemButton(
                    onPressed: () {},
                    child: const Text('Owner action'),
                  ),
                ],
              );
            },
          ),
        ),
      );
      for (final next in [second, null, first]) {
        final current = _triggerFocus(tester, 'Owner menu');
        current.requestFocus();
        await tester.pumpAndSettle();
        await _key(tester, LogicalKeyboardKey.enter, PhysicalKeyboardKey.enter);
        final before = closes;
        rebuild(() => owner = next);
        await tester.pumpAndSettle();
        final updated = _triggerFocus(tester, 'Owner menu');
        expect(updated.hasFocus, isTrue);
        expect(find.text('Owner action'), findsOneWidget);
        expect(
          closes,
          before,
          reason: 'Changing owner must keep the existing menu open.',
        );
        await _key(
          tester,
          LogicalKeyboardKey.escape,
          PhysicalKeyboardKey.escape,
        );
        expect(find.text('Owner action'), findsNothing);
        expect(closes, before + 1);
        expect(updated.hasFocus, isTrue);
      }
      expect(opens, 3);
      expect(closes, 3);
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              TextButton(
                focusNode: first,
                onPressed: () {},
                child: const Text('First remains'),
              ),
              TextButton(
                focusNode: second,
                onPressed: () {},
                child: const Text('Second remains'),
              ),
            ],
          ),
        ),
      );
      first.requestFocus();
      await tester.pumpAndSettle();
      expect(first.hasFocus, isTrue);
      second.requestFocus();
      await tester.pumpAndSettle();
      expect(second.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('owner replacement preserves a focused menu item', (
    tester,
  ) async {
    final first = FocusNode(), second = FocusNode(), item = FocusNode();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    addTearDown(item.dispose);
    var changed = false, closes = 0;
    late StateSetter rebuild;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return GlassMenu(
              trigger: const Text('Item menu'),
              focusNode: changed ? second : first,
              onClose: () => closes++,
              items: [
                MenuItemButton(
                  focusNode: item,
                  onPressed: () {},
                  child: const Text('Focused item'),
                ),
              ],
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Item menu'));
    await tester.pumpAndSettle();
    item.requestFocus();
    await tester.pumpAndSettle();
    expect(item.hasFocus, isTrue);
    rebuild(() => changed = true);
    await tester.pumpAndSettle();
    expect(item.hasFocus, isTrue);
    expect(second.hasFocus, isFalse);
    await _key(tester, LogicalKeyboardKey.escape, PhysicalKeyboardKey.escape);
    expect(find.text('Focused item'), findsNothing);
    expect(closes, 1);
    expect(second.hasFocus, isTrue);
  });

  testWidgets('pending owner migration respects current state and unmount', (
    tester,
  ) async {
    final first = FocusNode(), second = FocusNode();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    FocusNode? owner = first;
    late StateSetter rebuild;
    var enabled = true, empty = false, closes = 0;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return GlassMenu(
              trigger: const Text('Pending menu'),
              focusNode: owner,
              enabled: enabled,
              onClose: () => closes++,
              items: empty
                  ? const []
                  : [
                      MenuItemButton(
                        onPressed: () {},
                        child: const Text('Pending action'),
                      ),
                    ],
            );
          },
        ),
      ),
    );
    first.requestFocus();
    await tester.pumpAndSettle();
    await _key(tester, LogicalKeyboardKey.enter, PhysicalKeyboardKey.enter);
    rebuild(() => owner = second);
    await tester.pump();
    rebuild(() => owner = null);
    await tester.pumpAndSettle();
    final implicit = _triggerFocus(tester, 'Pending menu');
    expect(implicit.hasFocus, isTrue);
    rebuild(() => empty = true);
    await tester.pumpAndSettle();
    expect(find.text('Pending action'), findsNothing);
    expect(closes, 1);
    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNull,
    );
    rebuild(() {
      empty = false;
      owner = first;
    });
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pending menu'));
    await tester.pumpAndSettle();
    rebuild(() {
      owner = second;
      enabled = false;
    });
    await tester.pumpAndSettle();
    expect(closes, 2);
    expect(find.text('Pending action'), findsNothing);
    rebuild(() {
      owner = first;
      enabled = true;
    });
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pending menu'));
    await tester.pumpAndSettle();
    rebuild(() => owner = second);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(tester.binding.transientCallbackCount, 0);
  });
}
