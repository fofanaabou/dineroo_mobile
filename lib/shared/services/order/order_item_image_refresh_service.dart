import 'package:dineroo_mobile/customer/services/restaurant/restaurant_service.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/common/utils/restaurant_item_image_urls.dart';
import 'package:dineroo_mobile/shared/models/domain/order.dart';

class OrderItemImageRefreshService {
  final RestaurantService _restaurantService;
  final String _logPrefix;

  OrderItemImageRefreshService({
    RestaurantService? restaurantService,
    String logPrefix = 'OrderImages',
  }) : _restaurantService = restaurantService ?? RestaurantService(),
       _logPrefix = logPrefix;

  Future<List<Order>> refreshOrders(List<Order> orders) async {
    final imageUrlsByRestaurant = <String, Map<String, String>>{};

    for (final restaurantId
        in orders
            .where(_orderHasRefreshableItems)
            .map((order) => order.restaurantId)
            .toSet()) {
      if (restaurantId.isEmpty) continue;
      imageUrlsByRestaurant[restaurantId] = await _fetchFreshItemImageUrls(
        restaurantId,
      );
    }

    return orders
        .map(
          (order) => _withFreshItemImagesFromCache(
            order,
            imageUrlsByRestaurant[order.restaurantId] ?? const {},
          ),
        )
        .toList();
  }

  Future<Order> refreshOrder(Order order) async {
    if (order.restaurantId.isEmpty || !_orderHasRefreshableItems(order)) {
      return order;
    }

    final imageUrls = await _fetchFreshItemImageUrls(order.restaurantId);
    return _withFreshItemImagesFromCache(order, imageUrls);
  }

  bool _orderHasRefreshableItems(Order order) {
    return order.items.any((item) {
      final itemId = item.menuId ?? item.productId;
      return itemId != null && itemId.isNotEmpty;
    });
  }

  Order _withFreshItemImagesFromCache(
    Order order,
    Map<String, String> imageUrls,
  ) {
    if (imageUrls.isEmpty) return order;

    var changed = false;
    final items = order.items.map((item) {
      final itemId = item.menuId ?? item.productId;
      if (itemId == null || itemId.isEmpty) return item;

      final freshImageUrl = imageUrls[itemId];
      if (freshImageUrl == null || freshImageUrl.isEmpty) return item;
      if (freshImageUrl == item.imageUrl) return item;

      changed = true;
      return item.copyWith(imageUrl: freshImageUrl);
    }).toList();

    return changed ? order.copyWith(items: items) : order;
  }

  Future<Map<String, String>> _fetchFreshItemImageUrls(
    String restaurantId,
  ) async {
    try {
      final restaurantData = await _restaurantService.fetchRestaurant(
        restaurantId,
      );
      return extractRestaurantItemImageUrls(restaurantData);
    } catch (e, stack) {
      logger.w(
        '[$_logPrefix] Failed to refresh order images for restaurantId=$restaurantId',
        error: e,
        stackTrace: stack,
      );
      return const {};
    }
  }
}
