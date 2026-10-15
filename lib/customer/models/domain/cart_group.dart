import 'package:dineroo_mobile/customer/models/domain/cart_item.dart';
import 'package:dineroo_mobile/customer/models/domain/product_choice_item.dart';

class CartGroup {
  final String restaurantId;
  final String restaurantName;
  final String deliveryAddress;
  final List<CartItem> items;

  CartGroup({
    required this.restaurantId,
    required this.restaurantName,
    required this.deliveryAddress,
    required this.items,
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  List<Map<String, dynamic>> get estimationItems => items
      .map(
        (item) => {
          'quantity': item.quantity,
          'price': item.unitPrice,
          if (item.isConfiguredProduct) 'productId': item.product.id,
          if (item.isConfiguredMenu) ...{'menuId': item.product.id},
          if (item.isConfiguredItem)
            'selectedMenuItems': item.selectedMenuItems!
                .map(
                  (sel) => {
                    'groupId': sel.groupId,
                    'menuItemId': sel.menuItemId,
                    'productId': sel.productId,
                    if (sel.productChoices != null)
                      'productChoices':
                          ProductChoiceItem.listToJson(sel.productChoices!),
                  },
                )
                .toList(),
        },
      )
      .toList();
}
