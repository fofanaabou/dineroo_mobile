import 'package:dineroo_mobile/shared/common/constants/hive_type_ids.dart';
import 'package:hive/hive.dart';
import 'product.dart';
import 'selected_menu_item.dart';
import '../extensions/product_extensions.dart';

part 'cart_item.g.dart';

@HiveType(typeId: HiveTypeIds.cartItem)
class CartItem {
  @HiveField(0)
  final Product product;

  @HiveField(1)
  int quantity;

  @HiveField(2)
  final double? menuBasePrice;

  @HiveField(3)
  final List<SelectedMenuItem>? selectedMenuItems;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.menuBasePrice,
    this.selectedMenuItems,
  });

  bool get isConfiguredItem =>
      selectedMenuItems != null && menuBasePrice != null;

  bool get isConfiguredMenu => isConfiguredItem && product.isMenu;

  bool get isConfiguredProduct => isConfiguredItem && product.isProduct;

  double get unitPrice => isConfiguredItem
      ? (menuBasePrice! +
            selectedMenuItems!.fold<double>(
              0.0,
              (sum, item) => sum + item.additionalPrice,
            ))
      : product.price;

  double get totalPrice => unitPrice * quantity;
}
