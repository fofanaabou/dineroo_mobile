import 'package:dineroo_mobile/shared/models/domain/menu.dart';
import 'package:dineroo_mobile/shared/models/dto/menu_dto.dart';
import 'package:dineroo_mobile/manager/services/manager_menus_service.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_context_helper.dart';
import 'package:dineroo_mobile/shared/enums/user_role.dart';

class ManagerMenusRepository {
  final ManagerMenusService _service;

  ManagerMenusRepository({required ManagerMenusService service})
    : _service = service;

  Future<List<Menu>> fetchMenus(String restaurantId) async {
    final rawMenus = await _service.fetchMenus(
      restaurantId,
      context: resolveApiContext(UserRole.restaurantManager),
    );
    final dtos = rawMenus.map((e) => MenuDto.fromJson(e)).toList();
    return dtos.map((dto) => dto.toDomain()).toList();
  }

  Future<void> updateAvailability(
    String restaurantId,
    String menuId,
    bool available,
  ) {
    return _service.updateAvailability(restaurantId, menuId, available);
  }
}
