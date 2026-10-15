import 'package:dineroo_mobile/shared/models/domain/order.dart';
import 'package:dineroo_mobile/customer/exceptions/order_creation_exception.dart';
import 'package:dineroo_mobile/shared/models/dto/order_dto.dart';
import 'package:dineroo_mobile/customer/services/order/order_service.dart';
import 'package:dineroo_mobile/customer/services/order/order_list_service.dart';
import 'package:dineroo_mobile/customer/services/restaurant/restaurant_service.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/services/order/order_item_image_refresh_service.dart';
import 'package:dineroo_mobile/shared/services/order/shared_order_service.dart';

class OrderRepository {
  final OrderService _orderService;
  final OrderListService _listService;
  final SharedOrderService _sharedOrderService;
  final OrderItemImageRefreshService _imageRefreshService;

  OrderRepository({
    required OrderService orderService,
    required OrderListService listService,
    required SharedOrderService sharedOrderService,
    RestaurantService? restaurantService,
  }) : _orderService = orderService,
       _listService = listService,
       _sharedOrderService = sharedOrderService,
       _imageRefreshService = OrderItemImageRefreshService(
         restaurantService: restaurantService,
       );

  Future<Order> createOrder(Map<String, dynamic> orderData) async {
    try {
      final data = await _orderService.createOrder(orderData);
      return _imageRefreshService.refreshOrder(
        OrderDto.fromJson(data).toDomain(),
      );
    } on OrderCreationException {
      rethrow;
    } catch (e, stack) {
      logger.e('Failed to create order', error: e, stackTrace: stack);
      throw Exception('Failed to create order');
    }
  }

  Future<List<Order>> fetchOrders(String customerId) async {
    try {
      final data = await _listService.fetchOrders(customerId);
      final dtos = data.map((e) => OrderDto.fromJson(e)).toList();
      return _imageRefreshService.refreshOrders(
        dtos.map((dto) => dto.toDomain()).toList(),
      );
    } catch (e, stack) {
      logger.e('Failed to fetch orders', error: e, stackTrace: stack);
      throw Exception('Failed to fetch orders');
    }
  }

  Future<Order> fetchOrderById(dynamic orderId) async {
    try {
      final data = await _sharedOrderService.fetchOrderById(orderId);
      return _imageRefreshService.refreshOrder(
        OrderDto.fromJson(data).toDomain(),
      );
    } catch (e, stack) {
      logger.e('Failed to fetch order by id', error: e, stackTrace: stack);
      throw Exception('Failed to fetch order');
    }
  }
}
