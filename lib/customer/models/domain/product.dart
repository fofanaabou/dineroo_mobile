import 'package:dineroo_mobile/shared/common/constants/hive_type_ids.dart';
import 'package:hive/hive.dart';
import 'package:dineroo_mobile/customer/models/dto/product_dto.dart';
import 'choice_group.dart';

part 'product.g.dart';

@HiveType(typeId: HiveTypeIds.product)
class Product {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double price;

  @HiveField(3)
  final String imageUrl;

  @HiveField(4)
  final String category;

  @HiveField(5)
  final String restaurantId;

  @HiveField(6)
  final String restaurantName;

  @HiveField(7)
  bool available;

  @HiveField(8)
  final bool canBeSoldAlone;

  @HiveField(9)
  final String description;

  final List<ChoiceGroup> choiceGroups;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.restaurantId,
    required this.restaurantName,
    this.available = true,
    this.canBeSoldAlone = true,
    this.description = '',
    this.choiceGroups = const [],
  });

  Product copyWith({
    String? id,
    String? name,
    double? price,
    String? imageUrl,
    String? category,
    String? restaurantId,
    String? restaurantName,
    bool? available,
    bool? canBeSoldAlone,
    String? description,
    List<ChoiceGroup>? choiceGroups,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      available: available ?? this.available,
      canBeSoldAlone: canBeSoldAlone ?? this.canBeSoldAlone,
      description: description ?? this.description,
      choiceGroups: choiceGroups ?? this.choiceGroups,
    );
  }

  factory Product.fromDto(ProductDto dto) => Product(
    id: dto.id,
    name: dto.name,
    price: dto.price,
    imageUrl: dto.imageUrl,
    category: dto.productType,
    restaurantId: dto.restaurantId,
    restaurantName: dto.restaurantName,
    available: dto.available,
    canBeSoldAlone: dto.canBeSoldAlone,
    description: dto.description,
    choiceGroups: dto.choiceGroups.map((e) => e.toDomain()).toList(),
  );
}
