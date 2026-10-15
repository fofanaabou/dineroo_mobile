import 'package:dineroo_mobile/shared/models/domain/opening_hours.dart';
import 'package:dineroo_mobile/shared/models/domain/suspension.dart';
import '../../../shared/models/dto/opening_hours_dto.dart';
import '../../../shared/models/dto/menu_dto.dart';
import 'product_dto.dart';
import '../domain/restaurant_detail.dart';

class RestaurantDetailDto {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final String description;
  final String imageUrl;
  final List<MenuDto> menus;
  final List<ProductDto> products;
  final List<OpeningHoursDto> openingHours;
  final Suspension? suspension;

  RestaurantDetailDto({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    required this.description,
    required this.imageUrl,
    required this.menus,
    required this.products,
    required this.openingHours,
    this.suspension,
  });

  factory RestaurantDetailDto.fromJson(Map<String, dynamic> json) {
    return RestaurantDetailDto(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      menus:
          (json['menus'] as List? ?? [])
              .map((e) => MenuDto.fromJson(e))
              .toList(),
      products:
          (json['products'] as List? ?? [])
              .map((e) => ProductDto.fromJson(e))
              .toList(),
      openingHours:
          (json['openingHours'] as List? ?? [])
              .map((e) => OpeningHoursDto.fromJson(e))
              .toList(),
      suspension: Suspension.fromRestaurantJson(json['suspension']),
    );
  }

  RestaurantDetail toDomain() {
    return RestaurantDetail(
      id: id,
      name: name,
      address: address,
      phone: phone ?? '',
      description: description,
      imageUrl: imageUrl,
      menus: menus.map((e) => e.toDomain()).toList(),
      products: products.map((e) => e.toDomain()).toList(),
      openingHours:
          openingHours
              .map(
                (dto) => OpeningHours(
                  day: dto.day,
                  timeRanges:
                      dto.timeRanges
                          .map((t) => TimeRange(start: t.start, end: t.end))
                          .toList(),
                ),
              )
              .toList(),
      suspension: suspension,
    );
  }
}
