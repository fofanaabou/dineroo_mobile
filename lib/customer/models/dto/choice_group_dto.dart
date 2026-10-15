import '../domain/choice_group.dart';

class ChoiceItemDto {
  final String id;
  final String productId;
  final String productName;
  final String productImageUrl;
  final String productDescription;
  final bool productConfigurable;
  final double additionalPrice;
  final bool available;
  final int displayOrder;

  ChoiceItemDto({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImageUrl = '',
    this.productDescription = '',
    this.productConfigurable = false,
    this.additionalPrice = 0.0,
    this.available = true,
    this.displayOrder = 0,
  });

  factory ChoiceItemDto.fromJson(Map<String, dynamic> json) {
    return ChoiceItemDto(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      productImageUrl:
          (json['productImageUrl'] ?? json['product_image_url'])?.toString() ??
          '',
      productDescription:
          (json['productDescription'] ?? json['product_description'])
              ?.toString() ??
          '',
      productConfigurable:
          json['productConfigurable'] ?? json['product_configurable'] ?? false,
      additionalPrice:
          ((json['additionalPrice'] ?? json['additional_price']) as num?)
              ?.toDouble() ??
          0.0,
      available: json['available'] ?? true,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
    );
  }

  ChoiceItem toDomain() => ChoiceItem(
    id: id,
    productId: productId,
    productName: productName,
    productImageUrl: productImageUrl,
    productDescription: productDescription,
    productConfigurable: productConfigurable,
    additionalPrice: additionalPrice,
    available: available,
    displayOrder: displayOrder,
  );
}

class ChoiceGroupDto {
  final String id;
  final String name;
  final bool required;
  final int minSelections;
  final int maxSelections;
  final int displayOrder;
  final List<ChoiceItemDto> items;

  ChoiceGroupDto({
    required this.id,
    required this.name,
    this.required = false,
    this.minSelections = 1,
    this.maxSelections = 1,
    this.displayOrder = 0,
    required this.items,
  });

  factory ChoiceGroupDto.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'] as List? ?? [];
    return ChoiceGroupDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      required: json['required'] ?? false,
      minSelections: (json['minSelections'] as num?)?.toInt() ?? 1,
      maxSelections: (json['maxSelections'] as num?)?.toInt() ?? 1,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      items: itemsRaw
          .map((e) => ChoiceItemDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  ChoiceGroup toDomain() => ChoiceGroup(
    id: id,
    name: name,
    required: required,
    minSelections: minSelections,
    maxSelections: maxSelections,
    displayOrder: displayOrder,
    items: items.map((e) => e.toDomain()).toList(),
  );
}
