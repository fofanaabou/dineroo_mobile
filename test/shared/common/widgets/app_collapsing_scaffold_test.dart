import 'package:dineroo_mobile/shared/common/widgets/app_collapsing_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders title and back button and body', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppCollapsingScaffold(
          title: 'Mon Restaurant',
          imageUrl: '',
          slivers: [SliverToBoxAdapter(child: Text('Body content'))],
          showCartAction: false,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Mon Restaurant'), findsWidgets);
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    expect(find.text('Body content'), findsOneWidget);
  });

  testWidgets('shows cart icon when enabled', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppCollapsingScaffold(
          title: 'Test',
          imageUrl: '',
          slivers: [],
          showCartAction: true,
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
  });

  testWidgets('wraps scroll view with refresh when onRefresh is set', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppCollapsingScaffold(
          title: 'Test',
          imageUrl: '',
          slivers: [],
          onRefresh: () async {},
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(RefreshIndicator), findsOneWidget);
  });
}
