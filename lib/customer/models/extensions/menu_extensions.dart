import 'package:dineroo_mobile/shared/models/domain/menu.dart';
import 'package:dineroo_mobile/customer/models/domain/product.dart';

extension MenuExtensions on Menu {
  Product toProduct({
    required String restaurantId,
    required String restaurantName,
  }) {
    return Product(
      id: id,
      name: name,
      price: price,
      imageUrl: imageUrl,
      category: 'menu',
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      canBeSoldAlone: false,
    );
  }
}
