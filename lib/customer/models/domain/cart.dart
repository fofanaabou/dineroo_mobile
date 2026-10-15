import 'cart_item.dart';

class Cart {
  final List<CartItem> items;
  final String? restaurantId;
  final String? deliveryAddress;

  Cart({this.items = const [], this.restaurantId, this.deliveryAddress});
}
