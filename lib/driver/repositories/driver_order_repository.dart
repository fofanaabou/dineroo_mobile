import 'package:dineroo_mobile/customer/services/restaurant/restaurant_service.dart';
import 'package:dineroo_mobile/shared/models/domain/order.dart';
import 'package:dineroo_mobile/shared/models/domain/order_details.dart';
import 'package:dineroo_mobile/shared/models/dto/order_dto.dart';
import 'package:dineroo_mobile/shared/repositories/order_details_repository.dart';
import 'package:dineroo_mobile/shared/services/order/order_item_image_refresh_service.dart';
import 'package:dineroo_mobile/shared/services/order/shared_order_service.dart';

class DriverOrderRepository {
  final SharedOrderService _orderService;
  final OrderDetailsRepository _orderDetailsRepository;
  final OrderItemImageRefreshService _imageRefreshService;

  DriverOrderRepository({
    required SharedOrderService orderService,
    required OrderDetailsRepository orderDetailsRepository,
    RestaurantService? restaurantService,
  }) : _orderService = orderService,
       _orderDetailsRepository = orderDetailsRepository,
       _imageRefreshService = OrderItemImageRefreshService(
         restaurantService: restaurantService,
         logPrefix: 'DriverOrderImages',
       );

  Future<Order> fetchOrderById(String orderId) async {
    final json = await _orderService.fetchOrderById(orderId);
    return _imageRefreshService.refreshOrder(
      OrderDto.fromJson(json).toDomain(),
    );
  }

  Future<List<Order>> fetchOrdersByIds(List<String> orderIds) async {
    final jsonOrders = await _orderService.fetchOrdersByIds(orderIds);
    final orders = jsonOrders
        .map((json) => OrderDto.fromJson(json).toDomain())
        .toList();
    return _imageRefreshService.refreshOrders(orders);
  }

  Future<OrderDetails?> fetchOrderDetails(String orderId) {
    return _orderDetailsRepository.fetchOrderDetails(orderId);
  }
}
