import 'package:dineroo_mobile/customer/models/domain/product.dart';
import 'package:dineroo_mobile/customer/models/dto/product_dto.dart';
import 'package:dineroo_mobile/manager/services/manager_products_service.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_context_helper.dart';
import 'package:dineroo_mobile/shared/enums/user_role.dart';

class ManagerProductsRepository {
  final ManagerProductsService _service;

  ManagerProductsRepository({required ManagerProductsService service})
    : _service = service;

  Future<List<Product>> fetchProducts(String restaurantId) async {
    final raw = await _service.fetchProducts(
      restaurantId,
      context: resolveApiContext(UserRole.restaurantManager),
    );
    final dtos = raw.map((e) => ProductDto.fromJson(e)).toList();
    return dtos.map((dto) => dto.toDomain()).toList();
  }

  Future<void> updateAvailability(
    String restaurantId,
    String productId,
    bool available,
  ) {
    return _service.updateAvailability(restaurantId, productId, available);
  }
}
