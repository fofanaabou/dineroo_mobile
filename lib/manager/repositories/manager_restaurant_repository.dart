import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_context_helper.dart';
import 'package:dineroo_mobile/shared/enums/user_role.dart';
import 'package:dineroo_mobile/customer/models/domain/restaurant.dart';
import '../services/manager_restaurant_service.dart';

class ManagerRestaurantRepository {
  final ManagerRestaurantService service;

  ManagerRestaurantRepository({required this.service});

  Future<Restaurant> fetchRestaurant(String restaurantId) async {
    final json = await service.fetchRestaurant(
      restaurantId,
      context: resolveApiContext(UserRole.restaurantManager),
    );
    return Restaurant.fromJson(json);
  }

  Future<void> updateOpeningHours(
    String restaurantId,
    List<Map<String, dynamic>> openingHours,
  ) async {
    try {
      await service.updateOpeningHours(restaurantId, openingHours);
    } catch (e, stack) {
      logger.e('Error updating opening hours', error: e, stackTrace: stack);
      rethrow;
    }
  }
}
