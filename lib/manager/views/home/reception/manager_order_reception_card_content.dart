import 'package:dineroo_mobile/manager/views/home/details/manager_order_item_row.dart';
import 'package:dineroo_mobile/shared/common/helpers/price_helper.dart';
import 'package:dineroo_mobile/shared/enums/order_status.dart';
import 'package:dineroo_mobile/shared/views/orders/order_card_container.dart';
import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/models/domain/order.dart';
import 'package:dineroo_mobile/shared/views/orders/order_action_buttons/order_accept_button.dart';
import 'package:dineroo_mobile/shared/views/orders/order_action_buttons/order_reject_button.dart';

class ManagerOrderReceptionCardContent extends StatelessWidget {
  final Order order;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final bool enabled;

  const ManagerOrderReceptionCardContent({
    super.key,
    required this.order,
    required this.onAccept,
    required this.onReject,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    final double sectionSpacing = isPortrait ? 16 : 8;
    final double smallSpacing = isPortrait ? 8 : 4;
    final double fontSizeTitle = isPortrait ? 16 : 10;
    final double fontSizeText = isPortrait ? 14 : 8;
    final double commentFontSize = isPortrait ? 12 : 8;

    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final remainingCount = order.items.length > 1 ? order.items.length - 1 : 0;

    return OrderCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: OrderStatus.created.color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'NOUVEAU',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: fontSizeText,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade400),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatPrice(order.totalPrice),
                      style: TextStyle(
                        fontSize: isPortrait ? 16 : 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: sectionSpacing),
          Text(
            'Commande #${order.shortId}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: fontSizeTitle,
            ),
          ),
          SizedBox(height: smallSpacing),
          if (firstItem != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ManagerOrderItemRow(item: firstItem),
            ),
          if (remainingCount > 0) ...[
            const SizedBox(height: 4),
            Text(
              '+ $remainingCount autre${remainingCount > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: fontSizeText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          SizedBox(height: sectionSpacing),
          if (order.hasComment) ...[
            Text(
              'Commentaire',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSizeTitle,
              ),
            ),
            SizedBox(height: smallSpacing),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFFF7F7F7),
              ),
              child: Text(
                order.comment!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: commentFontSize,
                  color: Colors.black54,
                ),
              ),
            ),
            SizedBox(height: sectionSpacing),
          ],
          Row(
            children: [
              Expanded(
                child: OrderRejectButton(
                  orderId: order.id.toString(),
                  isSmall: !isPortrait,
                  enabled: enabled,
                  onRejected: enabled ? onReject : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OrderAcceptButton(
                  orderId: order.id.toString(),
                  isSmall: !isPortrait,
                  enabled: enabled,
                  onAccepted: enabled ? onAccept : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
