import '../domain/restaurant.dart';
import '../../../shared/models/dto/opening_hours_dto.dart';
import '../../../shared/models/domain/opening_hours.dart';

class RestaurantDto {
  final String id;
  final String name;
  final String imageUrl;
  final String? description;
  final String phone;
  final List<OpeningHoursDto> openingHours;
  final double? distanceKm;

  RestaurantDto({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.description,
    required this.phone,
    required this.openingHours,
    this.distanceKm,
  });

  factory RestaurantDto.fromJson(Map<String, dynamic> json) {
    return RestaurantDto(
      id: json['id'],
      name: json['name'],
      imageUrl: json['imageUrl'],
      description: json['description'],
      phone: json['phone']?.toString() ?? '',
      openingHours:
          (json['openingHours'] as List? ?? [])
              .map((e) => OpeningHoursDto.fromJson(e))
              .toList(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }

  Restaurant toDomain() {
    return Restaurant(
      id: id,
      name: name,
      imageUrl: imageUrl,
      description: description ?? '',
      phone: phone,
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
      distanceKm: distanceKm,
    );
  }
}
