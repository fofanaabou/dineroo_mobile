import 'package:dineroo_mobile/customer/models/domain/restaurant.dart';
import 'package:dineroo_mobile/customer/models/domain/restaurant_detail.dart';

extension RestaurantDetailExtensions on RestaurantDetail {
  Restaurant toRestaurant() {
    return Restaurant(
      id: id,
      name: name,
      imageUrl: imageUrl,
      description: description,
      phone: phone,
      openingHours: openingHours,
    );
  }
}
