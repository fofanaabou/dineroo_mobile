import 'package:dineroo_mobile/shared/common/widgets/app_add_button.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_dialog.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_paginated_list.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppSearchBar trims callbacks and clears text', (tester) async {
    final controller = TextEditingController(text: 'riz');
    addTearDown(controller.dispose);
    var changed = '';
    var submitted = '';
    var cleared = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSearchBar(
            controller: controller,
            hintText: 'Chercher un plat',
            onChanged: (value) => changed = value,
            onSubmitted: (value) => submitted = value,
            onClear: () => cleared = true,
          ),
        ),
      ),
    );

    expect(find.text('Chercher un plat'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '  pizza  ');
    await tester.testTextInput.receiveAction(TextInputAction.done);

    expect(changed, 'pizza');
    expect(submitted, 'pizza');

    await tester.tap(find.byIcon(Icons.close));

    expect(controller.text, isEmpty);
    expect(cleared, isTrue);
  });

  testWidgets('AppSearchBar ignores blank callbacks and enforces max length', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var callCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSearchBar(
            controller: controller,
            maxLength: 4,
            onChanged: (_) => callCount++,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '   ');
    await tester.enterText(find.byType(TextField), 'abcdef');

    expect(callCount, 1);
    expect(controller.text, 'abcd');
  });

  testWidgets('AppPaginatedList renders items, refreshes and loads more', (
    tester,
  ) async {
    var loadMoreCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 300,
            child: AppPaginatedList<int>(
              items: List.generate(20, (index) => index),
              itemBuilder: (item) =>
                  SizedBox(height: 40, child: Text('item-$item')),
              onRefresh: () async {},
              onLoadMore: () async => loadMoreCount++,
              canLoadMore: true,
              isLoading: false,
            ),
          ),
        ),
      ),
    );

    expect(find.text('item-0'), findsOneWidget);

    await tester.fling(find.byType(ListView), const Offset(0, -1000), 1000);
    await tester.pump();

    expect(loadMoreCount, greaterThanOrEqualTo(1));
    expect(find.byType(AppLoader), findsOneWidget);

    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('AppPaginatedList hides loader when there is no next page', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppPaginatedList<int>(
            items: const [1],
            itemBuilder: (item) => Text('item-$item'),
            onRefresh: () async {},
            onLoadMore: () async {},
            canLoadMore: false,
            isLoading: false,
          ),
        ),
      ),
    );

    expect(find.text('item-1'), findsOneWidget);
    expect(find.byType(AppLoader), findsNothing);
  });

  testWidgets('AppDialog renders message and handles actions', (tester) async {
    var confirmed = false;
    var cancelled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => AppDialog(
                    title: 'Confirmer',
                    message: 'Continuer ?',
                    confirmText: 'Oui',
                    cancelText: 'Non',
                    onConfirm: () => confirmed = true,
                    onCancel: () => cancelled = true,
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmer'), findsOneWidget);
    expect(find.text('Continuer ?'), findsOneWidget);
    expect(find.text('OUI'), findsOneWidget);
    expect(find.text('NON'), findsOneWidget);

    await tester.tap(find.text('NON'));
    expect(cancelled, isTrue);

    await tester.tap(find.text('OUI'));
    expect(confirmed, isTrue);
  });

  testWidgets('AppDialog supports custom content and validates arguments', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppDialog(
            title: 'Info',
            content: RichText(text: const TextSpan(text: 'Rich content')),
            showCancel: false,
            isShiftedUp: true,
          ),
        ),
      ),
    );

    expect(find.text('Info'), findsOneWidget);
    expect(find.text('VALIDER'), findsOneWidget);
    expect(find.text('ANNULER'), findsNothing);

    expect(
      () => const AppDialog(
        title: 'Invalid',
      ).build(tester.element(find.byType(AppDialog))),
      throwsArgumentError,
    );
  });

  testWidgets('AppAddButton triggers callback and shows disabled state', (
    tester,
  ) async {
    var addCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AppAddButton(onTap: () => addCount++)),
      ),
    );

    expect(find.byIcon(Icons.add_rounded), findsOneWidget);

    await tester.tap(find.byType(AppAddButton));
    await tester.pump();

    expect(addCount, 1);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: const AppAddButton(onTap: null))),
    );

    final button = tester.widget<AppAddButton>(find.byType(AppAddButton));
    expect(button.onTap, isNull);
  });
}
