class ManagerMenuItem {
  final String id;
  final String productId;
  final String productName;
  final String productImageUrl;
  final double additionalPrice;
  final int displayOrder;
  bool available;

  ManagerMenuItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImageUrl = '',
    this.additionalPrice = 0,
    this.displayOrder = 0,
    this.available = true,
  });

  factory ManagerMenuItem.fromJson(Map<String, dynamic> json) {
    return ManagerMenuItem(
      id: json['id'] ?? '',
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      productImageUrl: json['productImageUrl'] ?? '',
      additionalPrice: (json['additionalPrice'] as num?)?.toDouble() ?? 0,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      available: json['available'] ?? true,
    );
  }
}

class ManagerChoiceGroup {
  final String id;
  final String name;
  final bool required;
  final int minSelections;
  final int maxSelections;
  final int displayOrder;
  final List<ManagerMenuItem> items;

  ManagerChoiceGroup({
    required this.id,
    required this.name,
    this.required = false,
    this.minSelections = 0,
    this.maxSelections = 0,
    this.displayOrder = 0,
    required this.items,
  });

  factory ManagerChoiceGroup.fromJson(Map<String, dynamic> json) {
    return ManagerChoiceGroup(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      required: json['required'] ?? false,
      minSelections: (json['minSelections'] as num?)?.toInt() ?? 0,
      maxSelections: (json['maxSelections'] as num?)?.toInt() ?? 0,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => ManagerMenuItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ManagerMenuDetail {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double basePrice;
  bool available;
  final List<ManagerChoiceGroup> groups;

  ManagerMenuDetail({
    required this.id,
    required this.name,
    this.description = '',
    this.imageUrl = '',
    this.basePrice = 0,
    this.available = true,
    required this.groups,
  });

  factory ManagerMenuDetail.fromJson(Map<String, dynamic> json) {
    return ManagerMenuDetail(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0,
      available: json['available'] ?? true,
      groups: (json['groups'] as List<dynamic>?)
              ?.map(
                  (e) => ManagerChoiceGroup.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
