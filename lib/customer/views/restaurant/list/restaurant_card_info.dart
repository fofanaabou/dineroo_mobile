import 'package:flutter/material.dart';
import 'package:dineroo_mobile/customer/models/domain/restaurant.dart';
import 'package:dineroo_mobile/shared/common/widgets/restaurant_open_status_badge.dart';

class RestaurantCardInfo extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantCardInfo({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          restaurant.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF040404),
          ),
        ),
        const SizedBox(height: 4),
        RestaurantOpenStatusBadge(openingHours: restaurant.openingHours),
        const SizedBox(height: 4),
        if (restaurant.distanceKm != null)
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16),
              const SizedBox(width: 4),
              Text(
                '${restaurant.distanceKm!.toStringAsFixed(1)} km',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
        const SizedBox(height: 4),
        Text(
          restaurant.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, color: Color(0xFF696969)),
        ),
      ],
    );
  }
}
