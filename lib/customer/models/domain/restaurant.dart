import '../../../shared/models/domain/opening_hours.dart';
import '../../../shared/models/domain/suspension.dart';

class Restaurant {
  final String id;
  final String name;
  final String imageUrl;
  final String description;
  final String phone;
  final List<OpeningHours> openingHours;
  final double? distanceKm;
  final Suspension? suspension;

  Restaurant({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.phone,
    this.openingHours = const [],
    this.distanceKm,
    this.suspension,
  });

  bool get isSuspended => suspension != null;

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'],
      name: json['name'],
      imageUrl: json['imageUrl'],
      description: json['description'] ?? '',
      phone: json['phone'] ?? '',
      openingHours:
          (json['openingHours'] as List<dynamic>?)
              ?.map((e) => OpeningHours.fromJson(e))
              .toList() ??
          [],
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      suspension: Suspension.fromRestaurantJson(json['suspension']),
    );
  }
}
