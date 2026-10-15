import 'package:dineroo_mobile/customer/models/domain/restaurant.dart';
import 'package:dineroo_mobile/customer/views/restaurant/list/restaurant_card.dart';
import 'package:dineroo_mobile/shared/models/domain/opening_hours.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RestaurantCard', () {
    final allDayHours = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ]
        .map((day) => OpeningHours(
              day: day,
              timeRanges: [TimeRange(start: '00:00', end: '23:59')],
            ))
        .toList();

    testWidgets('renders restaurant name and open status', (tester) async {
      final restaurant = Restaurant(
        id: 'r1',
        name: 'Chez Mariam',
        imageUrl: 'https://example.com/image.jpg',
        description: 'Description du restaurant',
        phone: '1234567890',
        openingHours: allDayHours,
      );

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: RestaurantCard(restaurant: restaurant))),
      );
      await tester.pump();

      expect(find.text('Chez Mariam'), findsOneWidget);
      expect(find.text('Restaurant ouvert'), findsOneWidget);
    });

    testWidgets('shows distance when available', (tester) async {
      final restaurant = Restaurant(
        id: 'r1',
        name: 'Chez Mariam',
        imageUrl: '',
        description: '',
        phone: '',
        openingHours: allDayHours,
        distanceKm: 3.5,
      );

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: RestaurantCard(restaurant: restaurant))),
      );
      await tester.pump();

      expect(find.text('3.5 km'), findsOneWidget);
    });

    testWidgets('shows distance warning dialog when distance > 10km',
        (tester) async {
      final restaurant = Restaurant(
        id: 'r1',
        name: 'Chez Mariam',
        imageUrl: '',
        description: '',
        phone: '',
        openingHours: allDayHours,
        distanceKm: 15.0,
      );

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: RestaurantCard(restaurant: restaurant))),
      );
      await tester.pump();

      await tester.tap(find.byType(RestaurantCard));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('⚠️ Restaurant éloigné'), findsOneWidget);
      expect(find.text('CONTINUER'), findsOneWidget);
    });
  });
}
