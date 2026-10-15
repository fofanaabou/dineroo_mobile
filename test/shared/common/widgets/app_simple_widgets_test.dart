import 'package:dineroo_mobile/shared/common/widgets/app_address_row.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_avatar.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_close_button.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_contact_card.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_empty_state.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_restaurant_name.dart';
import 'package:dineroo_mobile/shared/models/domain/contact.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('AppCloseButton', () {
    testWidgets('calls onPressed when tapped', (tester) async {
      var taps = 0;

      await tester.pumpWidget(
        buildSubject(AppCloseButton(onPressed: () => taps++)),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byType(IconButton));

      expect(taps, 1);
    });
  });

  group('AppAddressRow', () {
    testWidgets('renders location icon and address', (tester) async {
      await tester.pumpWidget(
        buildSubject(const AppAddressRow(address: 'Kipé, Ratoma')),
      );

      expect(find.byIcon(Icons.location_on), findsOneWidget);
      expect(find.text('Kipé, Ratoma'), findsOneWidget);
    });
  });

  group('AppEmptyState', () {
    testWidgets('renders configured icon and message', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          const AppEmptyState(icon: Icons.inbox, message: 'Aucun élément'),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.inbox));
      final text = tester.widget<Text>(find.text('Aucun élément'));

      expect(icon.size, 48);
      expect(icon.color, Colors.grey);
      expect(text.style?.color, Colors.grey);
    });
  });

  group('AppRestaurantName', () {
    testWidgets('renders nothing for blank name', (tester) async {
      await tester.pumpWidget(
        buildSubject(const AppRestaurantName(name: '  ')),
      );

      expect(find.byIcon(Icons.storefront_outlined), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('trims and displays restaurant name', (tester) async {
      await tester.pumpWidget(
        buildSubject(const AppRestaurantName(name: '  Chez Fatou  ')),
      );

      final align = tester.widget<Align>(find.byType(Align));
      final text = tester.widget<Text>(find.text('Chez Fatou'));

      expect(find.byIcon(Icons.storefront_outlined), findsOneWidget);
      expect(align.alignment, Alignment.centerLeft);
      expect(text.overflow, TextOverflow.ellipsis);
    });

    testWidgets('can center the restaurant name', (tester) async {
      await tester.pumpWidget(
        buildSubject(const AppRestaurantName(name: 'Dineroo', centered: true)),
      );

      expect(
        tester.widget<Align>(find.byType(Align)).alignment,
        Alignment.center,
      );
    });
  });

  group('AppAvatar', () {
    testWidgets('shows default avatar for empty image url', (tester) async {
      await tester.pumpWidget(buildSubject(const AppAvatar(imageUrl: '  ')));

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });

  group('AppContactCard', () {
    testWidgets('renders contact details without call button', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          AppContactCard(
            contact: Contact(
              name: 'Mamadou Barry',
              subtitle: 'Livreur',
              phoneNumber: '620000000',
            ),
            showCallButton: false,
          ),
        ),
      );

      expect(find.text('Mamadou Barry'), findsOneWidget);
      expect(find.text('Livreur'), findsOneWidget);
      expect(find.byIcon(Icons.phone), findsNothing);
    });

    testWidgets('hides blank subtitle and falls back to Client name', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          AppContactCard(
            contact: Contact(name: ' ', subtitle: ' ', phoneNumber: ''),
            showCallButton: false,
          ),
        ),
      );

      expect(find.text('Client'), findsOneWidget);
      expect(find.text(' '), findsNothing);
    });
  });
}
