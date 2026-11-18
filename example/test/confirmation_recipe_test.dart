import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass_example/recipes/confirmation_recipe.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

void main() {
  testWidgets('ordinary dialog returns confirm, cancel, and no result', (
    tester,
  ) async {
    await tester.pumpWidget(const ConfirmationRecipeDemo());
    final open = find.text('打开普通弹窗');

    await tester.tap(open);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('结果：确认'), findsOneWidget);

    await tester.tap(open);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('结果：取消'), findsOneWidget);

    await tester.tap(open);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.text('结果：无值关闭'), findsOneWidget);
  });

  testWidgets('Tab stays in the dialog and Escape restores trigger focus', (
    tester,
  ) async {
    final triggerFocus = FocusNode();
    addTearDown(triggerFocus.dispose);
    final results = <bool?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              focusNode: triggerFocus,
              autofocus: true,
              onPressed: () async {
                results.add(
                  await showConfirmation(
                    context,
                    title: 'Confirm',
                    content: const Text('Continue?'),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(triggerFocus.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    final initialDialogFocus = FocusManager.instance.primaryFocus;
    expect(initialDialogFocus, isNotNull);
    expect(triggerFocus.hasFocus, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, isNot(same(initialDialogFocus)));
    expect(triggerFocus.hasFocus, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, same(initialDialogFocus));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(results, <bool?>[null]);
    expect(triggerFocus.hasPrimaryFocus, isTrue);
  });

  testWidgets('root and local dialogs close on the navigator they opened on', (
    tester,
  ) async {
    final rootObserver = _DialogObserver();
    final localObserver = _DialogObserver();
    final results = <bool?>[];
    const accent = Color(0xFF176847);
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [rootObserver],
        home: Navigator(
          observers: [localObserver],
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (context) => LiquidGlassTheme(
              data: const LiquidGlassThemeData(accentColor: accent),
              child: Scaffold(
                body: Builder(
                  builder: (context) => Column(
                    children: [
                      for (final root in [false, true])
                        TextButton(
                          onPressed: () async {
                            results.add(
                              await showConfirmation(
                                context,
                                title: 'Confirm',
                                content: const Text('Continue?'),
                                glass: true,
                                useRootNavigator: root,
                              ),
                            );
                          },
                          child: Text(root ? 'Root' : 'Local'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    for (final root in [false, true]) {
      await tester.tap(find.text(root ? 'Root' : 'Local'));
      await tester.pumpAndSettle();
      final dialog = find.byType(GlassDialog);
      expect(LiquidGlassTheme.of(tester.element(dialog)).accentColor, accent);
      expect(rootObserver.pushes, root ? 1 : 0);
      expect(localObserver.pushes, 1);
      await tester.tap(find.text(root ? 'Cancel' : 'OK'));
      await tester.pumpAndSettle();
      expect(rootObserver.pops, root ? 1 : 0);
      expect(localObserver.pops, 1);
      expect(find.text('Local'), findsOneWidget);
      expect(find.text('Root'), findsOneWidget);
    }
    expect(results, <bool?>[true, false]);
  });

  testWidgets('narrow glass dialog scrolls at 2x with transitions disabled', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 550);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final results = <bool?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
                disableAnimations: true,
              ),
              child: Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    results.add(
                      await showConfirmation(
                        context,
                        title: 'Confirm',
                        content: Text(List.filled(40, '长内容。').join()),
                        glass: true,
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final dialog = find.byType(GlassDialog);
    expect(
      find.descendant(
        of: dialog,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.namesRoute == true &&
              widget.properties.label == 'Confirm',
        ),
      ),
      findsOneWidget,
    );
    final route = ModalRoute.of(tester.element(dialog))!;
    expect(route.transitionDuration, Duration.zero);
    expect(route.reverseTransitionDuration, Duration.zero);
    final scrollable = find.descendant(
      of: dialog,
      matching: find.byType(Scrollable),
    );
    expect(
      tester.state<ScrollableState>(scrollable).position.maxScrollExtent,
      greaterThan(0),
    );
    final confirm = find.text('OK');
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(results, <bool?>[true]);
  });
}

class _DialogObserver extends NavigatorObserver {
  int pushes = 0;
  int pops = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is DialogRoute<bool>) pushes++;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is DialogRoute<bool>) pops++;
  }
}
