import 'dart:async';

import 'package:dineroo_mobile/driver/views/home/card/driver_card_restaurant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DriverCardRestaurant rendering', () {
    testWidgets('renders restaurant name and order reference', (tester) async {
      await tester.pumpWidget(_TestApp(
        child: DriverCardRestaurant(
          restaurantName: 'Chez Mariam',
          orderId: 'order-1',
          onPrimaryAction: () async => null,
          onClose: () {},
        ),
      ));

      expect(find.text('Restaurant'), findsOneWidget);
      expect(find.text('Chez Mariam'), findsOneWidget);
      expect(find.text('Commande #1'), findsOneWidget);
      expect(find.text("J'ai récupéré la commande"), findsOneWidget);
    });

    testWidgets('renders estimated time when provided', (tester) async {
      await tester.pumpWidget(_TestApp(
        child: DriverCardRestaurant(
          estimatedTime: 'à 2.5 km',
          onPrimaryAction: () async => null,
          onClose: () {},
        ),
      ));

      expect(find.text('à 2.5 km'), findsOneWidget);
    });

    testWidgets('renders start address when provided', (tester) async {
      await tester.pumpWidget(_TestApp(
        child: DriverCardRestaurant(
          startAddress: 'Kaloum, Conakry',
          onPrimaryAction: () async => null,
          onClose: () {},
        ),
      ));

      expect(find.text('Kaloum, Conakry'), findsOneWidget);
    });

    testWidgets('renders OTP code when provided', (tester) async {
      await tester.pumpWidget(_TestApp(
        child: DriverCardRestaurant(
          pickupOtpCode: '1234',
          onPrimaryAction: () async => null,
          onClose: () {},
        ),
      ));

      expect(find.text('Code à donner au restaurant'), findsOneWidget);
      expect(find.text('1234'), findsOneWidget);
    });

    testWidgets('does not render OTP when pickupOtpCode is null',
        (tester) async {
      await tester.pumpWidget(_TestApp(
        child: DriverCardRestaurant(
          onPrimaryAction: () async => null,
          onClose: () {},
        ),
      ));

      expect(find.text('Code à donner au restaurant'), findsNothing);
    });

    testWidgets('renders call button when phone is provided', (tester) async {
      await tester.pumpWidget(_TestApp(
        child: DriverCardRestaurant(
          restaurantPhone: '620000000',
          onPrimaryAction: () async => null,
          onClose: () {},
        ),
      ));

      expect(find.byIcon(Icons.call), findsOneWidget);
    });

    testWidgets('does not render call button without phone', (tester) async {
      await tester.pumpWidget(_TestApp(
        child: DriverCardRestaurant(
          onPrimaryAction: () async => null,
          onClose: () {},
        ),
      ));

      expect(find.byIcon(Icons.call), findsNothing);
    });

    testWidgets('uses default restaurant name when not provided',
        (tester) async {
      await tester.pumpWidget(_TestApp(
        child: DriverCardRestaurant(
          onPrimaryAction: () async => null,
          onClose: () {},
        ),
      ));

      expect(find.text('Restaurant'), findsNWidgets(2));
    });
  });

  group('DriverCardRestaurant actions', () {
    testWidgets('shows spinner while loading', (tester) async {
      final action = Completer<String?>();
      await tester.pumpWidget(_TestApp(
        child: DriverCardRestaurant(
          onPrimaryAction: () => action.future,
          onClose: () {},
        ),
      ));

      await tester.tap(find.text("J'ai récupéré la commande"));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text("J'ai récupéré la commande"), findsNothing);

      action.complete(null);
    });

    testWidgets('shows error when primary action returns message',
        (tester) async {
      await tester.pumpWidget(_TestApp(
        child: DriverCardRestaurant(
          onPrimaryAction: () async =>
              'Veuillez demander au restaurant de valider votre code.',
          onClose: () {},
        ),
      ));

      await tester.tap(find.text("J'ai récupéré la commande"));
      await tester.pump();
      await tester.pump();

      expect(
        find.text(
          'Veuillez demander au restaurant de valider votre code.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows error when primary action throws', (tester) async {
      await tester.pumpWidget(_TestApp(
        child: DriverCardRestaurant(
          onPrimaryAction: () async => throw Exception('Server error'),
          onClose: () {},
        ),
      ));

      await tester.tap(find.text("J'ai récupéré la commande"));
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Une erreur est survenue. Veuillez réessayer.'),
        findsOneWidget,
      );
    });

    testWidgets('pops dialog on success when inside dialog', (tester) async {
      await tester.pumpWidget(_DialogHarness(
        card: DriverCardRestaurant(
          onPrimaryAction: () async => null,
          onClose: () {},
        ),
      ));

      await tester.tap(find.text('ouvrir'));
      await tester.pump();

      await tester.tap(find.text("J'ai récupéré la commande"));
      await tester.pump();
      await tester.pump();

      expect(find.byType(DriverCardRestaurant), findsNothing);
    });

    testWidgets('close button calls onClose callback', (tester) async {
      var closed = false;
      await tester.pumpWidget(_DialogHarness(
        card: DriverCardRestaurant(
          onPrimaryAction: () async => null,
          onClose: () => closed = true,
        ),
      ));

      await tester.tap(find.text('ouvrir'));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(closed, isTrue);
      expect(find.byType(DriverCardRestaurant), findsNothing);
    });

    testWidgets('hides close button while loading', (tester) async {
      final action = Completer<String?>();
      await tester.pumpWidget(_TestApp(
        child: DriverCardRestaurant(
          onPrimaryAction: () => action.future,
          onClose: () {},
        ),
      ));

      await tester.tap(find.text("J'ai récupéré la commande"));
      await tester.pump();

      expect(find.byIcon(Icons.close), findsNothing);

      action.complete(null);
    });
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }
}

class _DialogHarness extends StatelessWidget {
  const _DialogHarness({required this.card});

  final Widget card;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => Dialog(child: card),
              ),
              child: const Text('ouvrir'),
            );
          },
        ),
      ),
    );
  }
}
