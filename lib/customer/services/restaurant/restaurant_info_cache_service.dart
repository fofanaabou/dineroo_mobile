import 'package:dineroo_mobile/customer/services/restaurant/restaurant_service.dart';

class RestaurantInfoCacheService {
  RestaurantInfoCacheService._();

  static final Map<String, Future<Map<String, dynamic>>> _restaurantById = {};

  static Future<Map<String, dynamic>> fetchRestaurant(String restaurantId) {
    return _restaurantById.putIfAbsent(
      restaurantId,
      () => RestaurantService().fetchRestaurant(restaurantId),
    );
  }

  static Future<String> resolveRestaurantName({
    required String restaurantId,
    required String restaurantName,
  }) async {
    final directName = restaurantName.trim();
    if (directName.isNotEmpty) return directName;

    final trimmedRestaurantId = restaurantId.trim();
    if (trimmedRestaurantId.isEmpty) return '';

    try {
      final json = await fetchRestaurant(trimmedRestaurantId);
      return (json['name'] ?? '').toString().trim();
    } catch (_) {
      return '';
    }
  }

  static void invalidate(String restaurantId) {
    _restaurantById.remove(restaurantId);
  }

  static void clear() {
    _restaurantById.clear();
  }
}
