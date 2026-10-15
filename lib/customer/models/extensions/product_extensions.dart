import 'package:dineroo_mobile/customer/models/domain/product.dart';

extension ProductCategoryExtension on Product {
  bool get isMenu => category == 'menu';
  bool get isProduct => !isMenu;
}
