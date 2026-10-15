import 'package:dineroo_mobile/customer/repositories/order_repository.dart';
import 'package:dineroo_mobile/customer/services/order/order_list_service.dart';
import 'package:dineroo_mobile/customer/services/order/order_service.dart';
import 'package:dineroo_mobile/customer/services/restaurant/restaurant_service.dart';
import 'package:dineroo_mobile/shared/services/order/shared_order_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderRepository', () {
    test('refreshes order item image urls from restaurant detail', () async {
      final repository = OrderRepository(
        orderService: _FakeOrderService(),
        listService: _FakeOrderListService([
          _orderJson(
            orderItems: [
              _orderItemJson(
                id: 1,
                productId: 'product-1',
                imageUrl: 'https://stale.test/product.jpg',
              ),
              _orderItemJson(
                id: 2,
                menuId: 'menu-1',
                imageUrl: 'https://stale.test/menu.jpg',
              ),
            ],
          ),
        ]),
        sharedOrderService: _FakeSharedOrderService(),
        restaurantService: _FakeRestaurantService({
          'id': 'restaurant-1',
          'menus': [
            {'id': 'menu-1', 'imageUrl': 'https://wasabi.test/menu-1.jpg'},
          ],
          'products': [
            {
              'id': 'product-1',
              'imageUrl': 'https://wasabi.test/product-1.jpg',
            },
          ],
        }),
      );

      final orders = await repository.fetchOrders('customer-1');

      expect(
        orders.single.items.first.imageUrl,
        'https://wasabi.test/product-1.jpg',
      );
      expect(
        orders.single.items.last.imageUrl,
        'https://wasabi.test/menu-1.jpg',
      );
    });
  });
}

Map<String, dynamic> _orderJson({
  required List<Map<String, dynamic>> orderItems,
}) {
  return {
    'id': '20260901-0001',
    'shortId': '0001',
    'restaurantId': 'restaurant-1',
    'restaurantName': 'Chez Fatou',
    'totalPrice': 10000,
    'deliveryContact': <String, dynamic>{},
    'status': 'CREATED',
    'createdDate': '2026-09-01T12:00:00Z',
    'lastModifiedDate': '2026-09-01T12:00:00Z',
    'orderItems': orderItems,
  };
}

Map<String, dynamic> _orderItemJson({
  required int id,
  String? menuId,
  String? productId,
  required String imageUrl,
}) {
  return {
    'id': id,
    'orderId': '20260901-0001',
    'menuId': menuId,
    'productId': productId,
    'imageUrl': imageUrl,
    'quantity': 1,
    'price': 10000,
    'itemName': 'Item $id',
  };
}

class _FakeOrderListService extends OrderListService {
  final List<Map<String, dynamic>> response;

  _FakeOrderListService(this.response);

  @override
  Future<List<Map<String, dynamic>>> fetchOrders(String customerId) async =>
      response;
}

class _FakeRestaurantService extends RestaurantService {
  final Map<String, dynamic> response;

  _FakeRestaurantService(this.response);

  @override
  Future<Map<String, dynamic>> fetchRestaurant(String id) async => response;
}

class _FakeOrderService extends OrderService {}

class _FakeSharedOrderService extends SharedOrderService {}
