import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';
import 'fixtures/desktop_consumer.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Windows native public desktop consumer', (tester) async {
    expect(Platform.isWindows, isTrue);
    await tester.pumpWidget(const DesktopConsumer());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Native draft');
    await tester.tap(find.byKey(const ValueKey('nav-b')));
    await tester.pumpAndSettle();
    expect(find.text('Selection: B'), findsOneWidget);
    expect(find.text('Draft: Native draft'), findsOneWidget);
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    expect(find.byType(GlassDialog), findsOneWidget);
    await tester.sendKeyEvent(
      LogicalKeyboardKey.escape,
      physicalKey: PhysicalKeyboardKey.escape,
    );
    await tester.pumpAndSettle();
    expect(find.byType(GlassDialog), findsNothing);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('tab-b')),
        matching: find.byIcon(Icons.close),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tab-b')), findsNothing);
    expect(find.text('Selection: A'), findsOneWidget);
    expect(tester.takeException(), isNull);
    binding.reportData = {
      'platform': Platform.operatingSystem,
      'native_functional': true,
      'input_transport': 'WidgetTester; physical IME not covered',
    };
  });
}
