import 'package:dineroo_mobile/customer/models/domain/menu_detail.dart';
import 'package:dineroo_mobile/customer/models/domain/choice_group.dart';
import 'package:dineroo_mobile/customer/models/domain/restaurant.dart';
import 'package:dineroo_mobile/customer/views/restaurant/menu/menu_detail_body.dart';
import 'package:dineroo_mobile/shared/models/domain/opening_hours.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget createTestApp(Widget body) {
  return MaterialApp(home: body);
}

void main() {
  group('MenuDetailBody', () {
    final allDayHours =
        [
              'MONDAY',
              'TUESDAY',
              'WEDNESDAY',
              'THURSDAY',
              'FRIDAY',
              'SATURDAY',
              'SUNDAY',
            ]
            .map(
              (day) => OpeningHours(
                day: day,
                timeRanges: [TimeRange(start: '00:00', end: '23:59')],
              ),
            )
            .toList();

    final restaurant = Restaurant(
      id: 'r1',
      name: 'Chez Mariam',
      imageUrl: '',
      description: '',
      phone: '',
      openingHours: allDayHours,
    );

    final menuDetail = MenuDetail(
      id: 'm1',
      name: 'Menu Test',
      price: 15.0,
      imageUrl: '',
      description: 'Un super menu',
      products: [],
    );

    testWidgets('renders menu name and description', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          MenuDetailBody(menuDetail: menuDetail, restaurant: restaurant),
        ),
      );
      await tester.pump();

      expect(find.text('Menu Test'), findsAtLeastNWidgets(1));
      expect(find.text('Un super menu'), findsOneWidget);
    });

    testWidgets('renders choice groups', (tester) async {
      final choiceItems = [
        ChoiceItem(id: 'ci1', productId: 'p1', productName: 'Frites'),
        ChoiceItem(id: 'ci2', productId: 'p2', productName: 'Salade'),
      ];
      final groups = [
        ChoiceGroup(
          id: 'g1',
          name: 'Accompagnement',
          required: true,
          items: choiceItems,
        ),
      ];
      final withGroups = MenuDetail(
        id: 'm1',
        name: 'Menu Test',
        price: 15,
        imageUrl: '',
        description: '',
        choiceGroups: groups,
      );

      await tester.pumpWidget(
        createTestApp(
          MenuDetailBody(menuDetail: withGroups, restaurant: restaurant),
        ),
      );
      await tester.pump();

      expect(find.text('Accompagnement'), findsOneWidget);
      expect(find.text('Frites'), findsOneWidget);
      expect(find.text('Salade'), findsOneWidget);
    });

    testWidgets('renders bottom bar with total price', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          MenuDetailBody(menuDetail: menuDetail, restaurant: restaurant),
        ),
      );
      await tester.pump();

      expect(find.text('Ajouter 15 GNF'), findsOneWidget);
    });
  });
}
