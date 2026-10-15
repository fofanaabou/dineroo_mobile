import 'package:dineroo_mobile/shared/common/constants/constants.dart';
import 'package:dineroo_mobile/shared/common/helpers/navigation_helper.dart';
import 'package:dineroo_mobile/customer/views/restaurant/detail/restaurant_detail_view.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_network_image.dart';
import 'package:dineroo_mobile/customer/views/restaurant/list/restaurant_card_info.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import '../../../models/domain/restaurant.dart';
import 'package:dineroo_mobile/shared/common/helpers/opening_hours_helper.dart';

class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantCard({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final isOpen = OpeningHoursHelper.restaurantIsOpen(restaurant.openingHours);

    return Opacity(
      opacity: isOpen ? 1.0 : 0.82,
      child: InkWell(
        onTap: () => _openRestaurantDetail(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppNetworkImage(
                imageUrl: restaurant.imageUrl,
                width: 120,
                height: 90,
              ),
              const SizedBox(width: 12),
              Expanded(child: RestaurantCardInfo(restaurant: restaurant)),
            ],
          ),
        ),
      ),
    );
  }

  void _openRestaurantDetail(BuildContext context) {
    final distance = restaurant.distanceKm;
    if (distance != null && distance > maxDeliveryDistanceKm) {
      showDialog(
        context: context,
        builder:
            (_) => AppDialog(
              title: '⚠️ Restaurant éloigné',
              message:
                  'Ce restaurant est à ${distance.toStringAsFixed(1)} km de votre position.\n'
                  'La livraison pourrait être plus longue.\n\n'
                  'Souhaitez-vous continuer ?',
              confirmText: 'Continuer',
              onConfirm: () {
                Navigator.pop(context);
                navigateTo(
                  context,
                  RestaurantDetailView(restaurantId: restaurant.id),
                );
              },
            ),
      );
      return;
    }

    navigateTo(context, RestaurantDetailView(restaurantId: restaurant.id));
  }
}
