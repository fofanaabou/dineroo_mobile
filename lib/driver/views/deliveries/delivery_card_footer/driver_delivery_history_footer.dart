import 'package:dineroo_mobile/driver/view_models/driver_order_history_view_model.dart';
import 'package:dineroo_mobile/shared/common/helpers/price_helper.dart';
import 'package:flutter/material.dart';

part 'driver_earning_banner.dart';
part 'delivery_history_destination_info.dart';

class DriverDeliveryHistoryFooter extends StatelessWidget {
  final DriverOrderHistoryItem item;

  const DriverDeliveryHistoryFooter({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final delivery = item.delivery;
    final driverEarning = delivery.deliveryFee;
    final destination =
        delivery.deliveryAddressLabel.isNotEmpty
            ? delivery.deliveryAddressLabel
            : item.order.deliveryAddress;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (driverEarning != null) ...[
              _DriverEarningBanner(value: formatPrice(driverEarning)),
              const SizedBox(height: 12),
            ],
            _DeliveryHistoryDestinationInfo(
              icon: Icons.location_on_outlined,
              label: 'Destination',
              value: destination,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
