import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/customer/models/dto/menu_with_restaurant.dart';
import 'package:dineroo_mobile/customer/services/restaurant/menu_service.dart';
import 'package:dineroo_mobile/customer/models/dto/menu_detail_dto.dart';
import 'package:dineroo_mobile/customer/models/domain/restaurant.dart';

class MenuRepository {
  final MenuService _service;

  MenuRepository(this._service);

  Future<MenuWithRestaurant> getMenuDetailWithRestaurant(
    Restaurant restaurant,
    String menuId,
  ) async {
    try {
      final menuJson = await _service.fetchMenuDetail(restaurant.id, menuId);
      final dto = MenuDetailDto.fromJson(menuJson);
      final menuDetail = dto.toDomain();

      return MenuWithRestaurant(menuDetail: menuDetail, restaurant: restaurant);
    } catch (e, stack) {
      logger.e(
        'Failed to load menu detail or restaurant',
        error: e,
        stackTrace: stack,
      );
      throw Exception('Failed to load menu detail or restaurant');
    }
  }
}
