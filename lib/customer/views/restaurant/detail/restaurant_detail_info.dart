import 'package:dineroo_mobile/customer/models/domain/restaurant_detail.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_info_pill.dart';
import 'package:dineroo_mobile/shared/common/widgets/restaurant_open_status_badge.dart';
import 'package:flutter/material.dart';

class RestaurantDetailInfo extends StatelessWidget {
  final RestaurantDetail restaurant;

  const RestaurantDetailInfo({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final standaloneProductCount = restaurant.products
        .where((product) => product.canBeSoldAlone)
        .length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  restaurant.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.verified_rounded,
                size: 22,
                color: Colors.deepOrange,
              ),
            ],
          ),
          if (restaurant.address.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.deepOrange,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    restaurant.address,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (restaurant.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              restaurant.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54, height: 1.35),
            ),
          ],
          const SizedBox(height: 12),
          RestaurantOpenStatusBadge(openingHours: restaurant.openingHours),
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(
                child: AppInfoPill(
                  icon: Icons.menu_book_outlined,
                  label:
                      '${restaurant.menus.length} menu${restaurant.menus.length > 1 ? 's' : ''}',
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: AppInfoPill(
                  icon: Icons.fastfood_outlined,
                  label:
                      '$standaloneProductCount produit${standaloneProductCount > 1 ? 's' : ''}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
