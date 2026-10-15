import 'package:dineroo_mobile/customer/models/domain/product.dart';
import 'package:dineroo_mobile/customer/models/domain/menu_detail.dart';

extension MenuDetailToProduct on MenuDetail {
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
