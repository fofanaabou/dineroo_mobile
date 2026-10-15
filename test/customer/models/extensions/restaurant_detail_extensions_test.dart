import 'package:dineroo_mobile/customer/models/domain/restaurant_detail.dart';
import 'package:dineroo_mobile/customer/models/extensions/restaurant_detail_extensions.dart';
import 'package:dineroo_mobile/shared/models/domain/opening_hours.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RestaurantDetailExtensions converts detail to restaurant summary', () {
    final openingHours = <OpeningHours>[
      OpeningHours(day: 'MONDAY', timeRanges: []),
    ];
    final detail = RestaurantDetail(
      id: 'restaurant-1',
      name: 'Chez Mariam',
      description: 'Cuisine locale',
      address: 'Kaloum',
      imageUrl: 'image.png',
      phone: '620000000',
      menus: const [],
      products: const [],
      openingHours: openingHours,
    );

    final restaurant = detail.toRestaurant();

    expect(restaurant.id, 'restaurant-1');
    expect(restaurant.name, 'Chez Mariam');
    expect(restaurant.description, 'Cuisine locale');
    expect(restaurant.imageUrl, 'image.png');
    expect(restaurant.phone, '620000000');
    expect(restaurant.openingHours, openingHours);
  });
}
