import 'package:dineroo_mobile/shared/models/domain/order.dart';
import 'package:dineroo_mobile/customer/models/domain/cart_item.dart';
import 'package:dineroo_mobile/customer/models/domain/product.dart';
import 'package:dineroo_mobile/shared/models/domain/menu.dart';
import 'package:dineroo_mobile/customer/models/extensions/menu_extensions.dart';

extension OrderToCart on Order {
  List<CartItem> toCartItems() {
    return items.map((item) {
      final product =
          item.isMenu
              ? Menu(
                id: item.menuId!,
                name: item.displayName,
                price: item.price,
                imageUrl: item.imageUrl,
                available: true,
              ).toProduct(
                restaurantId: restaurantId,
                restaurantName: restaurantName,
              )
              : Product(
                id: item.productId!,
                name: item.displayName,
                price: item.price,
                imageUrl: item.imageUrl,
                category: '',
                restaurantId: restaurantId,
                restaurantName: restaurantName,
              );

      return CartItem(product: product, quantity: item.quantity);
    }).toList();
  }
}
