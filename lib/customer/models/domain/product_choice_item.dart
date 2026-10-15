class ProductChoiceItem {
  final String groupId;
  final String groupName;
  final String itemId;
  final String itemName;
  final double additionalPrice;
  final int quantity;

  const ProductChoiceItem({
    required this.groupId,
    required this.groupName,
    required this.itemId,
    required this.itemName,
    this.additionalPrice = 0.0,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() => {
    'groupId': groupId,
    'groupName': groupName,
    'itemId': itemId,
    'itemName': itemName,
    'additionalPrice': additionalPrice,
    'quantity': quantity,
  };

  factory ProductChoiceItem.fromJson(Map<String, dynamic> json) =>
    ProductChoiceItem(
      groupId: json['groupId'] as String,
      groupName: json['groupName'] as String? ?? '',
      itemId: json['itemId'] as String,
      itemName: json['itemName'] as String? ?? '',
      additionalPrice: (json['additionalPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );

  static List<ProductChoiceItem> listFromJson(List<dynamic> jsonList) =>
    jsonList.map((e) => ProductChoiceItem.fromJson(e as Map<String, dynamic>)).toList();

  static List<Map<String, dynamic>> listToJson(List<ProductChoiceItem> items) =>
    items.map((e) => e.toJson()).toList();
}
