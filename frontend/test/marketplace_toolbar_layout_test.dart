import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:culpeo_studio/core/app_strings.dart' as app_strings;
import 'package:culpeo_studio/modules/marketplace/marketplace_screen.dart';

void main() {
  testWidgets('marketplace search stays overflow-free at narrow width', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(620, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: MarketplaceScreen()));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('marketplace-search-input')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('collapsed-search')), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    // Let the calls the screen fired while mounting give up, so no timer
    // outlives the test.
    await tester.pump(const Duration(milliseconds: 10));
  });

  testWidgets(
    'marketplace maps existing filters into the full-width engine strip',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final originalLanguage = app_strings.appLanguage;
      app_strings.appLanguage = 'de';
      addTearDown(() => app_strings.appLanguage = originalLanguage);

      await tester.pumpWidget(const MaterialApp(home: MarketplaceScreen()));
      await tester.pump();

      final filterStrip = find.byKey(
        const ValueKey('marketplace-filter-strip'),
      );
      final primaryFilterRow = find.byKey(
        const ValueKey('marketplace-primary-filter-row'),
      );
      final categoryDropdown = find.byKey(
        const ValueKey('marketplace-category-dropdown'),
      );
      final quantizationDropdown = find.byKey(
        const ValueKey('marketplace-quantization-dropdown'),
      );
      final sortDropdown = find.byKey(
        const ValueKey('marketplace-sort-dropdown'),
      );
      final toolbarActions = find.byKey(
        const ValueKey('marketplace-toolbar-actions'),
      );
      final categoryTriggerSurface = find.byKey(
        const ValueKey('marketplace-category-dropdown-trigger'),
      );

      expect(filterStrip, findsOneWidget);
      expect(tester.getSize(filterStrip).width, 1920);
      expect(toolbarActions, findsOneWidget);
      expect(
        find.byKey(const ValueKey('marketplace-toolbar-wiki')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('marketplace-toolbar-downloads')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('marketplace-toolbar-view-grid')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('marketplace-toolbar-view-list')),
        findsOneWidget,
      );
      final semantics = tester.ensureSemantics();
      final gridViewControl = find.byKey(
        const ValueKey('marketplace-toolbar-view-grid'),
      );
      final listViewControl = find.byKey(
        const ValueKey('marketplace-toolbar-view-list'),
      );
      expect(
        tester
            .getSemantics(gridViewControl)
            .getSemanticsData()
            .flagsCollection
            .isSelected
            .toBoolOrNull(),
        isTrue,
      );
      await tester.tap(listViewControl);
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        tester
            .getSemantics(listViewControl)
            .getSemanticsData()
            .flagsCollection
            .isSelected
            .toBoolOrNull(),
        isTrue,
      );
      await tester.tap(gridViewControl);
      await tester.pump(const Duration(milliseconds: 200));
      semantics.dispose();
      expect(
        find.byKey(const ValueKey('marketplace-search-input')),
        findsOneWidget,
      );
      expect(find.text('Filter Engine'), findsNothing);
      expect(find.text('Filter'), findsOneWidget);
      expect(find.text('Provider:'), findsOneWidget);
      expect(find.text('Sortierung:'), findsOneWidget);
      expect(find.text('HuggingFace'), findsOneWidget);
      expect(primaryFilterRow, findsOneWidget);
      expect(categoryDropdown, findsOneWidget);
      expect(quantizationDropdown, findsOneWidget);
      expect(sortDropdown, findsOneWidget);
      expect(
        find.descendant(of: primaryFilterRow, matching: categoryDropdown),
        findsOneWidget,
      );
      expect(
        find.descendant(of: primaryFilterRow, matching: quantizationDropdown),
        findsOneWidget,
      );
      expect(
        find.descendant(of: primaryFilterRow, matching: sortDropdown),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('marketplace-advanced-toggle')),
        findsNothing,
      );
      expect(find.text('Erweitert'), findsNothing);
      expect(
        find.byKey(const ValueKey('marketplace-empty-filter-state')),
        findsOneWidget,
      );

      final categoryRect = tester.getRect(categoryDropdown);
      final quantizationRect = tester.getRect(quantizationDropdown);
      final sortRect = tester.getRect(sortDropdown);
      expect(categoryRect.top, closeTo(sortRect.top, 1));
      expect(quantizationRect.top, closeTo(sortRect.top, 1));
      expect(categoryRect.height, closeTo(quantizationRect.height, 1));
      expect(quantizationRect.height, closeTo(sortRect.height, 1));
      expect(categoryRect.width, greaterThan(0));
      expect(quantizationRect.width, greaterThan(0));

      final categoryTriggerRect = tester.getRect(categoryTriggerSurface);
      await tester.tap(categoryDropdown);
      await tester.pumpAndSettle();

      final allCategoryOption = find.byKey(
        const ValueKey('marketplace-filter-option-category-'),
      );
      final chatCategoryOption = find.byKey(
        const ValueKey('marketplace-filter-option-category-chat'),
      );
      expect(allCategoryOption, findsOneWidget);
      expect(chatCategoryOption, findsOneWidget);
      expect(
        find.byKey(const ValueKey('marketplace-filter-option-category-code')),
        findsOneWidget,
      );

      final allCategoryOptionRect = tester.getRect(allCategoryOption);
      expect(
        allCategoryOptionRect.left,
        closeTo(categoryTriggerRect.left + 4, 2),
      );
      expect(
        allCategoryOptionRect.top,
        inInclusiveRange(
          categoryTriggerRect.bottom - 2,
          categoryTriggerRect.bottom + 10,
        ),
      );
      expect(
        allCategoryOptionRect.width,
        closeTo(categoryTriggerRect.width - 8, 2),
      );

      await tester.tap(chatCategoryOption);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('marketplace-active-filter-category-chat')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('marketplace-empty-filter-state')),
        findsNothing,
      );

      await tester.tap(categoryDropdown);
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey('marketplace-filter-option-selected-category-chat'),
        ),
        findsOneWidget,
      );
      await tester.tap(chatCategoryOption);
      await tester.pumpAndSettle();

      Future<void> pick(Finder trigger, String optionKey) async {
        await tester.tap(trigger);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey(optionKey)));
        await tester.pumpAndSettle();
      }

      await pick(
        quantizationDropdown,
        'marketplace-filter-option-quantization-Q4_K_M',
      );

      expect(
        find.byKey(
          const ValueKey('marketplace-active-filter-quantization-Q4_K_M'),
        ),
        findsOneWidget,
      );

      await pick(sortDropdown, 'marketplace-filter-option-sort-newest');
      expect(
        find.byKey(const ValueKey('marketplace-active-filter-sort-newest')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
