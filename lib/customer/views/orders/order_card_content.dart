import 'package:dineroo_mobile/shared/common/helpers/price_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_network_image.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_restaurant_name.dart';
import 'package:flutter/material.dart';

class OrderCardContent extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String? restaurantName;
  final num price;
  final int itemsCount;
  final String? date;
  final bool hidePrice;

  const OrderCardContent({
    super.key,
    required this.imageUrl,
    required this.title,
    this.restaurantName,
    required this.price,
    required this.itemsCount,
    this.date,
    this.hidePrice = false,
  });

  @override
  Widget build(BuildContext context) {
    final details = [
      if (date != null) date!,
      '${itemsCount.toString().padLeft(2, '0')} article${itemsCount > 1 ? 's' : ''}',
    ].join(' | ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AppNetworkImage(imageUrl: imageUrl, width: 60, height: 60),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if ((restaurantName ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                AppRestaurantName(name: restaurantName),
              ],
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black54),
                  children: [
                    if (!hidePrice)
                      TextSpan(
                        text: formatPrice(price),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    TextSpan(text: hidePrice ? details : ' | $details'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
