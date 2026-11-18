import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass_example/recipes/feedback_recipe.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

void main() {
  const app = MaterialApp(home: FeedbackRecipe());
  final progress = find.byType(LinearProgressIndicator);
  final message = find.byType(SnackBar);
  final close = find.byTooltip('Close');

  testWidgets('inline feedback announces state and settles when idle', (
    tester,
  ) async {
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    void expectStatus(String label) {
      final status = find.semantics.byPredicate((node) {
        final data = node.getSemanticsData();
        return !node.isMergedIntoParent &&
            data.label == label &&
            data.flagsCollection.isLiveRegion;
      });
      expect(status.evaluate(), hasLength(1), reason: label);
      expect(tester.binding.hasScheduledFrame, isFalse);
    }

    Future<void> press(String label) async {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    expectStatus('暂无结果');
    await press('开始');
    expectStatus('等待进度');
    expect(progress, findsNothing);
    await press('模拟失败');
    expectStatus('处理失败');
    await press('重试');
    expectStatus('等待进度');
    await press('取消处理');
    expectStatus('暂无结果');
    await press('开始');
    await press('开始计量');
    final progressData = tester.getSemantics(progress).getSemanticsData();
    expect(progressData.label, '处理进度');
    expect(progressData.value, '25');
    for (final value in [0.5, 0.75]) {
      await press('推进进度');
      expect(tester.widget<LinearProgressIndicator>(progress).value, value);
    }
    await press('推进进度');
    expectStatus('处理完成');
    expect(progress, findsNothing);
    await press('返回空态');
    expectStatus('暂无结果');
  });

  testWidgets(
    'latest message replaces the current one without stealing focus',
    (tester) async {
      await tester.pumpWidget(app);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final triggerFocus = FocusManager.instance.primaryFocus;
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('已更新状态'), findsOneWidget);
      expect(FocusManager.instance.primaryFocus, same(triggerFocus));

      final liveMessage = find.semantics.byPredicate((node) {
        final data = node.getSemanticsData();
        return data.flagsCollection.isLiveRegion &&
            data.hasAction(SemanticsAction.dismiss);
      });
      expect(liveMessage.evaluate(), hasLength(1));

      // Replace again before the previous change has been drawn.
      await tester.tap(find.text('显示更新提示'));
      await tester.tap(find.text('显示结果提示'));
      await tester.pumpAndSettle();
      expect(message, findsOneWidget);
      expect(find.text('已更新状态'), findsNothing);
      expect(find.text('可查看处理结果'), findsOneWidget);
      await tester.tap(find.text('确认收到'));
      await tester.pumpAndSettle();
      expect(message, findsNothing);
      expect(find.text('已确认：可查看处理结果'), findsOneWidget);

      await tester.tap(find.text('显示更新提示'));
      await tester.pumpAndSettle();
      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(message, findsNothing);
      expect(find.text('已确认：已更新状态'), findsNothing);
      expect(tester.binding.hasScheduledFrame, isFalse);
    },
  );

  testWidgets('four motion preferences skip transitions and can be cleared', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(300, 480);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    Future<void> render([String? preference]) async {
      await tester.pumpWidget(
        MaterialApp(
          themeAnimationDuration: Duration.zero,
          theme: ThemeData(
            extensions: [
              LiquidGlassThemeData(
                accessibility: GlassAccessibilityConfig(
                  reduceMotion: preference == 'reduceMotion',
                ),
                performance: GlassPerformanceConfig(
                  enableAnimations: preference != 'enableAnimations',
                ),
              ),
            ],
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: preference == 'disableAnimations',
              accessibleNavigation: preference == 'accessibleNavigation',
            ),
            child: child!,
          ),
          home: const FeedbackRecipe(),
        ),
      );
      await tester.pumpAndSettle();
    }

    for (final preference in [
      'disableAnimations',
      'accessibleNavigation',
      'reduceMotion',
      'enableAnimations',
    ]) {
      await render(preference);
      await tester.tap(find.text('显示结果提示'));
      await tester.pump();
      expect(
        tester.widget<SnackBar>(message).animation!.value,
        1,
        reason: preference,
      );
      expect(close.hitTestable(), findsOneWidget);
      await tester.tap(close);
      await tester.pump();
      expect(message, findsNothing, reason: preference);
    }

    await render();
    await tester.tap(find.text('显示结果提示'));
    await tester.pump();
    expect(
      tester.widget<SnackBar>(message).animation!.status,
      AnimationStatus.forward,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 5));
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });
}
