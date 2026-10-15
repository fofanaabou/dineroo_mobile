import 'package:dineroo_mobile/customer/models/dto/restaurant_detail_dto.dart';
import '../../../shared/models/domain/opening_hours.dart';
import '../../../shared/models/domain/menu.dart';
import '../../../shared/models/domain/suspension.dart';
import 'product.dart';

class RestaurantDetail {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String description;
  final String imageUrl;
  final List<Menu> menus;
  final List<Product> products;
  final List<OpeningHours> openingHours;
  final Suspension? suspension;

  RestaurantDetail({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.description,
    required this.imageUrl,
    required this.menus,
    required this.products,
    this.openingHours = const [],
    this.suspension,
  });

  bool get isSuspended => suspension != null;

  factory RestaurantDetail.fromDto(RestaurantDetailDto dto) {
    return RestaurantDetail(
      id: dto.id,
      name: dto.name,
      address: dto.address,
      phone: dto.phone ?? '',
      description: dto.description,
      imageUrl: dto.imageUrl,
      menus: dto.menus.map((e) => Menu.fromDto(e)).toList(),
      products: dto.products.map((e) => Product.fromDto(e)).toList(),
      openingHours:
          dto.openingHours
              .map(
                (oh) => OpeningHours(
                  day: oh.day,
                  timeRanges:
                      oh.timeRanges
                          .map((t) => TimeRange(start: t.start, end: t.end))
                          .toList(),
                ),
              )
              .toList(),
      suspension: dto.suspension,
    );
  }
}
