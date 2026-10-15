import '../domain/product.dart';
import 'choice_group_dto.dart';

class ProductDto {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String description;
  final String productType;
  final String restaurantId;
  final String restaurantName;
  final bool available;
  final bool canBeSoldAlone;
  final List<ChoiceGroupDto> choiceGroups;

  ProductDto({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.description = '',
    required this.productType,
    required this.restaurantId,
    required this.restaurantName,
    required this.available,
    this.canBeSoldAlone = true,
    this.choiceGroups = const [],
  });

  factory ProductDto.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'];
    final price = (rawPrice as num?)?.toDouble();

    if (price == null) {
      throw Exception("ProductDto: 'price' is null or absent ➤ $json");
    }

    return ProductDto(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: price,
      imageUrl: json['imageUrl'] ?? '',
      description: json['description'] ?? '',
      productType: json['productType'] ?? '',
      restaurantId: json['restaurantId'] ?? '',
      restaurantName: json['restaurantName'] ?? '',
      available: json['available'] ?? false,
      canBeSoldAlone: json['canBeSoldAlone'] ?? true,
      choiceGroups:
          ((json['choiceGroups'] ?? json['groups']) as List?)
              ?.map((e) => ChoiceGroupDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Product toDomain() => Product(
    id: id,
    name: name,
    price: price,
    imageUrl: imageUrl,
    description: description,
    category: productType,
    restaurantId: restaurantId,
    restaurantName: restaurantName,
    available: available,
    canBeSoldAlone: canBeSoldAlone,
    choiceGroups: choiceGroups.map((e) => e.toDomain()).toList(),
  );
}
