import 'product_dto.dart';
import 'choice_group_dto.dart';
import '../domain/menu_detail.dart';

class MenuDetailDto {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String description;
  final List<ProductDto> products;
  final List<ChoiceGroupDto> choiceGroups;

  MenuDetailDto({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
    this.products = const [],
    this.choiceGroups = const [],
  });

  factory MenuDetailDto.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'] ?? json['basePrice'];
    final price = (rawPrice as num?)?.toDouble();

    if (price == null) {
      throw Exception("MenuDetailDto: 'price' is null or invalid ➤ $json");
    }

    return MenuDetailDto(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: price,
      imageUrl: json['imageUrl'] ?? '',
      description: json['description'] ?? '',
      products: (json['products'] as List?)
              ?.map((e) => ProductDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      choiceGroups: ((json['choiceGroups'] ?? json['groups']) as List?)
              ?.map((e) => ChoiceGroupDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  MenuDetail toDomain() => MenuDetail(
    id: id,
    name: name,
    price: price,
    imageUrl: imageUrl,
    description: description,
    products: products.map((e) => e.toDomain()).toList(),
    choiceGroups: choiceGroups.map((e) => e.toDomain()).toList(),
  );
}
