import 'package:dineroo_mobile/customer/services/restaurant/restaurant_service.dart';
import 'package:dineroo_mobile/shared/models/domain/order.dart';
import 'package:dineroo_mobile/shared/models/domain/order_details.dart';
import 'package:dineroo_mobile/shared/models/dto/order_dto.dart';
import 'package:dineroo_mobile/manager/services/manager_order_service.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_context_helper.dart';
import 'package:dineroo_mobile/shared/enums/user_role.dart';
import 'package:dineroo_mobile/shared/repositories/order_details_repository.dart';
import 'package:dineroo_mobile/shared/services/order/order_item_image_refresh_service.dart';

class ManagerOrderRepository {
  final ManagerOrderService _service;
  final OrderDetailsRepository? _orderDetailsRepository;
  final OrderItemImageRefreshService _imageRefreshService;

  ManagerOrderRepository({
    required ManagerOrderService service,
    OrderDetailsRepository? orderDetailsRepository,
    RestaurantService? restaurantService,
  }) : _service = service,
       _orderDetailsRepository = orderDetailsRepository,
       _imageRefreshService = OrderItemImageRefreshService(
         restaurantService: restaurantService,
         logPrefix: 'ManagerOrderImages',
       );

  static const UserRole _role = UserRole.restaurantManager;

  Future<List<Order>> fetchOrdersByRestaurant(String restaurantId) async {
    final data = await _service.fetchOrdersByRestaurant(
      restaurantId,
      context: resolveApiContext(_role),
    );
    final orders = data
        .map((dto) => OrderDto.fromJson(dto).toDomain())
        .toList();
    return _imageRefreshService.refreshOrders(orders);
  }

  Future<Order> fetchOrderById(String orderId) async {
    final json = await _service.fetchOrderById(
      orderId,
      context: resolveApiContext(_role),
    );
    return _imageRefreshService.refreshOrder(
      OrderDto.fromJson(json).toDomain(),
    );
  }

  Future<OrderDetails?> fetchOrderDetails(String orderId) async {
    if (_orderDetailsRepository == null) return null;
    return _orderDetailsRepository.fetchOrderDetails(orderId);
  }

  Future<void> acceptOrder(String restaurantId, String orderId) {
    return _service.acceptOrder(restaurantId: restaurantId, orderId: orderId);
  }

  Future<void> rejectOrder(String restaurantId, String orderId) {
    return _service.rejectOrder(restaurantId: restaurantId, orderId: orderId);
  }

  Future<void> updateOrderStatus({
    required String restaurantId,
    required String orderId,
    required String status,
  }) {
    return _service.updateOrderStatus(
      restaurantId: restaurantId,
      orderId: orderId,
      status: status,
    );
  }

  Future<String> validatePickupOtp({
    required String orderId,
    required String code,
    String? validatedBy,
    required String restaurantId,
  }) {
    return _service.validatePickupOtp(
      orderId: orderId,
      code: code,
      validatedBy: validatedBy,
      restaurantId: restaurantId,
    );
  }
}
