import 'package:dineroo_mobile/shared/common/helpers/price_helper.dart';
import 'package:dineroo_mobile/shared/models/domain/order.dart';
import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_network_image.dart';

class ManagerOrderItemRow extends StatelessWidget {
  final OrderItem item;

  const ManagerOrderItemRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final bool isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final double verticalPadding = isPortrait ? 8 : 2;
    final double imageSize = isPortrait ? 40 : 36;
    final double fontSize = isPortrait ? 14 : 12;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (item.imageUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AppNetworkImage(
                      imageUrl: item.imageUrl,
                      width: imageSize,
                      height: imageSize,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  '${item.quantity}×',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: fontSize),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatPrice(item.price),
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
