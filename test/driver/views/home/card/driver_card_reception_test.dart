import 'package:dineroo_mobile/driver/views/home/card/driver_card_reception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders ride details and starts notification sound', (
    tester,
  ) async {
    var plays = 0;
    var stops = 0;

    await tester.pumpWidget(
      _TestApp(
        child: DriverCardReception(
          price: 15000,
          restaurantDistanceLabel: 'Restaurant à 1,2 km',
          startAddress: 'Chez Mariam',
          endAddress: 'Kipé, Ratoma',
          onAccept: () {},
          onClose: () {},
          playSoundLoop: () => plays++,
          stopSound: () => stops++,
        ),
      ),
    );

    expect(plays, 1);
    expect(find.text('Montant de la course'), findsOneWidget);
    expect(find.text('15 000 GNF'), findsOneWidget);
    expect(find.text('Restaurant à 1,2 km'), findsOneWidget);
    expect(find.text('Chez Mariam'), findsOneWidget);
    expect(find.text('Kipé, Ratoma'), findsOneWidget);
    expect(find.textContaining('Accepter'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(stops, 1);
  });

  testWidgets('accept button stops sound and calls callback', (tester) async {
    var accepted = 0;
    var stopped = 0;

    await tester.pumpWidget(
      _DialogHarness(
        card: DriverCardReception(
          price: 15000,
          onAccept: () => accepted++,
          onClose: () {},
          playSoundLoop: () {},
          stopSound: () => stopped++,
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pump();

    await tester.tap(find.textContaining('Accepter'));
    await tester.pump();

    expect(accepted, 1);
    expect(stopped, greaterThanOrEqualTo(1));
    expect(find.byType(DriverCardReception), findsNothing);
  });

  testWidgets('close button stops sound and calls close callback', (
    tester,
  ) async {
    var closed = 0;
    var stopped = 0;

    await tester.pumpWidget(
      _DialogHarness(
        card: DriverCardReception(
          price: 15000,
          onAccept: () {},
          onClose: () => closed++,
          playSoundLoop: () {},
          stopSound: () => stopped++,
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    expect(closed, 1);
    expect(stopped, greaterThanOrEqualTo(1));
    expect(find.byType(DriverCardReception), findsNothing);
  });

  testWidgets('auto closes when countdown completes', (tester) async {
    var closed = 0;
    var stopped = 0;

    await tester.pumpWidget(
      _DialogHarness(
        card: DriverCardReception(
          price: 15000,
          onAccept: () {},
          onClose: () => closed++,
          playSoundLoop: () {},
          stopSound: () => stopped++,
          countdownDuration: const Duration(milliseconds: 20),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 25));
    await tester.pump(const Duration(milliseconds: 300));

    expect(closed, 1);
    expect(stopped, greaterThanOrEqualTo(1));
    expect(find.byType(DriverCardReception), findsNothing);
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
