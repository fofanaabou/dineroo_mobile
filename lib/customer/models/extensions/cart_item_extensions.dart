import 'package:dineroo_mobile/customer/models/domain/cart_item.dart';

extension CartItemToJson on CartItem {
  Map<String, dynamic> toJson() {
    return {
      'product_id': product.id,
      'name': product.name,
      'price': product.price,
      'category': product.category,
      'quantity': quantity,
      if (isConfiguredMenu) ...{
        'menu_base_price': menuBasePrice,
        'selected_items': selectedMenuItems!
            .map((e) => {
              'group_id': e.groupId,
              'product_id': e.productId,
              'product_name': e.productName,
              'additional_price': e.additionalPrice,
            })
            .toList(),
      },
    };
  }
}
