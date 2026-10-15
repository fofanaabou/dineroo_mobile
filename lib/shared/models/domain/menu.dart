import 'package:dineroo_mobile/shared/models/dto/menu_dto.dart';

class Menu {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final int groupCount;
  final int itemCount;
  bool available;

  Menu({
    required this.id,
    required this.name,
    this.description = '',
    required this.price,
    required this.imageUrl,
    this.groupCount = 0,
    this.itemCount = 0,
    required this.available,
  });

  factory Menu.fromDto(MenuDto dto) => Menu(
    id: dto.id,
    name: dto.name,
    description: dto.description,
    price: dto.price,
    imageUrl: dto.imageUrl,
    groupCount: dto.groupCount,
    itemCount: dto.itemCount,
    available: dto.available,
  );
}
