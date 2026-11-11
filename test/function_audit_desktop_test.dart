import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

Widget _host(Widget child, {LiquidGlassThemeData? glass}) => MaterialApp(
  theme: ThemeData(
    platform: TargetPlatform.windows,
    brightness: glass?.brightness ?? Brightness.light,
    extensions: [if (glass != null) glass],
  ),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  test('desktop constructors reject non-finite or negative geometry', () {
    for (final value in [-1.0, double.infinity, double.nan]) {
      expect(
        () => GlassNavigationItem(label: 'Invalid', indent: value),
        throwsAssertionError,
      );
      expect(
        () => GlassToolbar(spacing: value, children: const []),
        throwsAssertionError,
      );
    }
  });

  testWidgets('input switches external owners and forwards search callbacks', (
    tester,
  ) async {
    final first = TextEditingController(text: 'First');
    final second = TextEditingController(text: 'Second');
    final firstFocus = FocusNode();
    final secondFocus = FocusNode();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    addTearDown(firstFocus.dispose);
    addTearDown(secondFocus.dispose);
    final changes = <String>[];
    final submissions = <String>[];
    var useSecond = false;
    late StateSetter rebuild;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return GlassTextField(
              controller: useSecond ? second : first,
              focusNode: useSecond ? secondFocus : firstFocus,
              textInputAction: TextInputAction.search,
              onChanged: changes.add,
              onSubmitted: submissions.add,
              enabled: true,
              decoration: const InputDecoration(enabled: false),
            );
          },
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Edited first');
    rebuild(() => useSecond = true);
    await tester.pumpAndSettle();
    expect(find.text('Second'), findsOneWidget);
    expect(first.text, 'Edited first');
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Search result');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(changes, ['Edited first', 'Search result']);
    expect(submissions, ['Search result']);
    expect(firstFocus.hasFocus, isFalse);
    expect(first.text, 'Edited first');
    await tester.pumpWidget(const SizedBox.shrink());
    first.text = 'Owner one alive';
    second.text = 'Owner two alive';
    firstFocus.requestFocus();
    secondFocus.requestFocus();
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'high contrast input overrides foreground Paint / ${brightness.name}',
      (tester) async {
        final dark = brightness == Brightness.dark;
        final glass =
            (dark ? LiquidGlassThemeData.dark() : const LiquidGlassThemeData())
                .copyWith(
                  accessibility: const GlassAccessibilityConfig(
                    highContrast: true,
                  ),
                );
        final controller = TextEditingController(text: 'Readable');
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _host(
            GlassTextField(
              controller: controller,
              style: TextStyle(
                foreground: Paint()..color = dark ? Colors.black : Colors.white,
              ),
            ),
            glass: glass,
          ),
        );
        final editable = tester.widget<EditableText>(find.byType(EditableText));
        final actual = editable.style.foreground?.color ?? editable.style.color;
        expect(
          actual!.toARGB32(),
          (dark ? Colors.white : const Color(0xff17233b)).toARGB32(),
        );
      },
    );
  }

  testWidgets('selected navigation resolves declared state colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        GlassNavigationItem(
          label: 'Selected colors',
          selected: true,
          onPressed: () {},
          controlStyle: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith<Color>(
              (states) => states.contains(WidgetState.selected)
                  ? Colors.purple
                  : Colors.black,
            ),
            backgroundColor: WidgetStateProperty.resolveWith<Color>(
              (states) => states.contains(WidgetState.selected)
                  ? Colors.yellow
                  : Colors.white,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      DefaultTextStyle.of(
        tester.element(find.text('Selected colors')),
      ).style.color,
      Colors.purple,
    );
    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(TextButton),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, Colors.yellow);
  });

  testWidgets('selected navigation forwards selected state to shape resolver', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        GlassNavigationItem(
          label: 'Selected row',
          selected: true,
          onPressed: () {},
          controlStyle: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith<Color>(
              (states) => states.contains(WidgetState.selected)
                  ? Colors.purple
                  : Colors.black,
            ),
            shape: WidgetStateProperty.resolveWith<OutlinedBorder>(
              (states) => states.contains(WidgetState.selected)
                  ? const StadiumBorder()
                  : const RoundedRectangleBorder(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      DefaultTextStyle.of(
        tester.element(find.text('Selected row')),
      ).style.color,
      Colors.purple,
    );
    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(TextButton),
        matching: find.byType(Material),
      ),
    );
    expect(material.shape, isA<StadiumBorder>());
  });

  testWidgets('toolbar density and explicit spacing produce usable wraps', (
    tester,
  ) async {
    Widget scene(double? spacing) => _host(
      SizedBox(
        width: 110,
        child: GlassToolbar(
          spacing: spacing,
          children: const [
            SizedBox(key: ValueKey('first'), width: 48, height: 30),
            SizedBox(key: ValueKey('second'), width: 48, height: 30),
          ],
        ),
      ),
      glass: const LiquidGlassThemeData(visualDensity: VisualDensity.compact),
    );
    await tester.pumpWidget(scene(null));
    var a = tester.getRect(find.byKey(const ValueKey('first')));
    var b = tester.getRect(find.byKey(const ValueKey('second')));
    expect(b.top, a.top);
    expect(b.left - a.right, 8);
    await tester.pumpWidget(scene(20));
    a = tester.getRect(find.byKey(const ValueKey('first')));
    b = tester.getRect(find.byKey(const ValueKey('second')));
    expect(b.top - a.bottom, 20);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'app bar preferred size includes its bottom and matches Scaffold',
    (tester) async {
      const bar = GlassAppBar(
        title: Text('Window title'),
        toolbarHeight: 73,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(21),
          child: SizedBox(height: 21),
        ),
      );
      expect(bar.preferredSize, const Size.fromHeight(94));
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.windows),
          home: const Scaffold(
            appBar: bar,
            body: Align(
              alignment: Alignment.topLeft,
              child: Text('Body starts'),
            ),
          ),
        ),
      );
      expect(tester.getRect(find.text('Body starts')).top, 94);
      final sdkBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(sdkBar.automaticallyImplyLeading, isFalse);
      expect(sdkBar.toolbarHeight, 73);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('empty and disabled menus reject pointer and Enter activation', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    var opens = 0;
    for (final empty in [true, false]) {
      await tester.pumpWidget(
        _host(
          GlassMenu(
            trigger: const Text('Unavailable menu'),
            focusNode: focus,
            enabled: empty,
            onOpen: () => opens++,
            items: empty
                ? const []
                : [
                    MenuItemButton(
                      onPressed: () {},
                      child: const Text('Unavailable action'),
                    ),
                  ],
          ),
        ),
      );
      expect(
        tester.widget<TextButton>(find.byType(TextButton)).onPressed,
        isNull,
      );
      await tester.tap(find.text('Unavailable menu'), warnIfMissed: false);
      focus.requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        tester.widget<MenuAnchor>(find.byType(MenuAnchor)).controller!.isOpen,
        isFalse,
      );
      expect(opens, 0);
      expect(find.text('Unavailable action'), findsNothing);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    focus.requestFocus();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'menu owner replacement restores new focus and consumes outside tap',
    (tester) async {
      final firstFocus = FocusNode();
      final secondFocus = FocusNode();
      addTearDown(firstFocus.dispose);
      addTearDown(secondFocus.dispose);
      var replaceFocus = false, outside = 0, closed = 0;
      late StateSetter rebuild;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GlassMenu(
                    trigger: const Text('Menu owner'),
                    focusNode: replaceFocus ? secondFocus : firstFocus,
                    onClose: () => closed++,
                    items: [
                      MenuItemButton(
                        onPressed: () {},
                        child: const Text('Menu action'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 120),
                  TextButton(
                    onPressed: () => outside++,
                    child: const Text('Outside action'),
                  ),
                ],
              );
            },
          ),
        ),
      );
      firstFocus.requestFocus();
      await tester.pumpAndSettle();
      expect(firstFocus.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Outside action'));
      await tester.pumpAndSettle();
      expect(find.text('Menu action'), findsNothing);
      expect(outside, 0);
      expect(closed, 1);
      await tester.tap(find.text('Outside action'));
      await tester.pumpAndSettle();
      expect(outside, 1);
      firstFocus.requestFocus();
      await tester.pumpAndSettle();
      expect(firstFocus.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      rebuild(() => replaceFocus = true);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Menu action'), findsNothing);
      expect(closed, 2);
      expect(secondFocus.hasFocus, isTrue);
      expect(firstFocus.hasFocus, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      firstFocus.requestFocus();
      secondFocus.requestFocus();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'nested navigator dialog returns local result and keeps parent route',
    (tester) async {
      final nested = GlobalKey<NavigatorState>();
      String? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.windows),
          home: Navigator(
            key: nested,
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (context) => LiquidGlassTheme.merge(
                data: (parent) => parent.copyWith(
                  layout: parent.layout.copyWith(dialogMaxWidth: 270),
                ),
                child: Builder(
                  builder: (context) => Scaffold(
                    body: TextButton(
                      onPressed: () async {
                        result = await showGlassDialog<String>(
                          context: context,
                          useRootNavigator: false,
                          routeSettings: const RouteSettings(
                            name: 'nested-dialog',
                          ),
                          motion: const GlassMotionSpec(
                            transition: GlassTransition.none,
                          ),
                          builder: (context) => GlassDialog(
                            semanticLabel: 'Nested dialog',
                            padding: const EdgeInsets.all(7),
                            constraints: const BoxConstraints(maxWidth: 230),
                            content: const Text('Nested content'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, 'local'),
                                child: const Text('Complete nested'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text('Open nested'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open nested'));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(GlassDialog));
      expect(ModalRoute.of(context)!.settings.name, 'nested-dialog');
      expect(LiquidGlassTheme.of(context).layout.dialogMaxWidth, 270);
      expect(nested.currentState!.canPop(), isTrue);
      final actualWidth = tester.getSize(find.byType(GlassSurface)).width;
      await tester.tap(find.text('Complete nested'));
      await tester.pumpAndSettle();
      expect(result, 'local');
      expect(nested.currentState!.canPop(), isFalse);
      expect(find.text('Open nested'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(actualWidth, 230);
    },
  );

  testWidgets(
    'page route captures local theme and preserves public route options',
    (tester) async {
      late BuildContext source;
      await tester.pumpWidget(
        _host(
          LiquidGlassTheme.merge(
            data: (parent) => parent.copyWith(accentColor: Colors.teal),
            child: Builder(
              builder: (context) {
                source = context;
                return const Text('Source page');
              },
            ),
          ),
        ),
      );
      final route = GlassPageRoute<String>(
        context: source,
        reduceMotion: true,
        fullscreenDialog: true,
        settings: const RouteSettings(name: 'audited-page', arguments: 17),
        builder: (context) => Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.pop(context, 'returned'),
              child: Text(
                LiquidGlassTheme.of(context).accentColor.toARGB32().toString(),
              ),
            ),
          ),
        ),
      );
      expect(route.transitionDuration, Duration.zero);
      expect(route.reverseTransitionDuration, Duration.zero);
      expect(route.fullscreenDialog, isTrue);
      expect(route.settings.arguments, 17);
      final future = Navigator.of(source).push(route);
      await tester.pumpAndSettle();
      await tester.tap(find.text(Colors.teal.toARGB32().toString()));
      await tester.pumpAndSettle();
      expect(await future, 'returned');
      expect(find.text('Source page'), findsOneWidget);
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
