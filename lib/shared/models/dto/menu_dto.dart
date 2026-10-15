import '../domain/menu.dart';

class MenuDto {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final int groupCount;
  final int itemCount;
  final bool available;

  MenuDto({
    required this.id,
    required this.name,
    this.description = '',
    required this.price,
    required this.imageUrl,
    this.groupCount = 0,
    this.itemCount = 0,
    required this.available,
  });

  factory MenuDto.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'] ?? json['basePrice'];
    final price = (rawPrice as num?)?.toDouble();

    if (price == null) {
      throw Exception("MenuDto: 'price/basePrice' is null or absent ➤ $json");
    }

    final groups = (json['groups'] ?? json['choiceGroups']) as List?;
    final itemCount =
        groups?.fold<int>(0, (sum, group) {
          if (group is! Map<String, dynamic>) return sum;
          return sum + ((group['items'] as List?)?.length ?? 0);
        }) ??
        0;

    return MenuDto(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: price,
      imageUrl: json['imageUrl'] ?? '',
      groupCount: groups?.length ?? 0,
      itemCount: itemCount,
      available: json['available'] ?? false,
    );
  }

  Menu toDomain() => Menu(
    id: id,
    name: name,
    description: description,
    price: price,
    imageUrl: imageUrl,
    groupCount: groupCount,
    itemCount: itemCount,
    available: available,
  );
}
