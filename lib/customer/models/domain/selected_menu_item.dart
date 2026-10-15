import 'dart:convert';

import 'package:dineroo_mobile/shared/common/constants/hive_type_ids.dart';
import 'package:hive/hive.dart';
import 'product_choice_item.dart';

part 'selected_menu_item.g.dart';

@HiveType(typeId: HiveTypeIds.selectedMenuItem)
class SelectedMenuItem {
  @HiveField(0)
  final String groupId;

  @HiveField(1)
  final String groupName;

  @HiveField(2)
  final String menuItemId;

  @HiveField(3)
  final String productId;

  @HiveField(4)
  final String productName;

  @HiveField(5)
  final double additionalPrice;

  @HiveField(6)
  final String? productChoicesJson;

  SelectedMenuItem({
    required this.groupId,
    required this.groupName,
    required this.menuItemId,
    required this.productId,
    required this.productName,
    this.additionalPrice = 0.0,
    this.productChoicesJson,
  });

  List<ProductChoiceItem>? get productChoices {
    if (productChoicesJson == null || productChoicesJson!.isEmpty) return null;
    try {
      final decoded = jsonDecode(productChoicesJson!);
      return ProductChoiceItem.listFromJson(decoded as List<dynamic>);
    } catch (_) {
      return null;
    }
  }
}
