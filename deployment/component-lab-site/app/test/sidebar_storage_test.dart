import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass_component_lab/main.dart';

void main() {
  testWidgets(
    'scroll and expansion state survive repeated panel and layer switches',
    (tester) async {
      tester.view.physicalSize = const Size(1500, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const GlassLab());
      await tester.pumpAndSettle();
      final catalog = find.byKey(const PageStorageKey('component-catalog'));
      for (var i = 0; i < 8; i++) {
        await tester.drag(catalog, const Offset(0, -180));
        await tester.pumpAndSettle();
        double scrollOffset() => tester
            .state<ScrollableState>(
              find
                  .descendant(of: catalog, matching: find.byType(Scrollable))
                  .first,
            )
            .position
            .pixels;
        final offset = scrollOffset();
        await tester.tap(find.byKey(const ValueKey('nav-layers')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('nav-components')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'switch $i');
        expect(find.byType(ErrorWidget), findsNothing);
        expect(scrollOffset(), closeTo(offset, .5));
        final search = find.byKey(const ValueKey('basic-catalog-search'));
        await tester.enterText(search, '按钮');
        await tester.pumpAndSettle();
        final button = find.byKey(const ValueKey('basic-add-GlassButton'));
        final wasVisible = button.evaluate().isNotEmpty;
        await tester.tap(find.text('操作'));
        await tester.pumpAndSettle();
        expect(button.evaluate().isNotEmpty, !wasVisible);
        await tester.enterText(search, '');
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('收起组件面板'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('nav-components')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'collapse $i');
        expect(find.byType(ErrorWidget), findsNothing);
      }
      await tester.pumpWidget(const SizedBox());
    },
  );
}
