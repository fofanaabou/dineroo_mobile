import 'package:dineroo_mobile/shared/models/domain/order_details.dart';
import 'package:dineroo_mobile/shared/models/dto/order_details_dto.dart';
import 'package:dineroo_mobile/shared/services/order/order_details_service.dart';

class OrderDetailsRepository {
  final OrderDetailsService _service;

  OrderDetailsRepository({required OrderDetailsService service})
    : _service = service;

  Future<OrderDetails?> fetchOrderDetails(String orderId) async {
    final json = await _service.fetchOrderDetails(orderId);
    if (json == null) return null;

    return OrderDetailsDto.fromJson(json).toDomain();
  }
}
