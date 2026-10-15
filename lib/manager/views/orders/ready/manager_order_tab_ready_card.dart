import 'package:dineroo_mobile/manager/enums/order_source.dart';
import 'package:dineroo_mobile/manager/view_models/orders/manager_order_list_view_model.dart';
import 'package:dineroo_mobile/shared/common/helpers/navigation_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_avatar.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_call_button.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_chip.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:dineroo_mobile/shared/models/domain/contact.dart';
import 'package:dineroo_mobile/shared/models/domain/order.dart';
import 'package:dineroo_mobile/shared/views/orders/order_action_buttons/order_detail_button.dart';
import 'package:dineroo_mobile/shared/views/orders/order_action_buttons/order_give_to_driver_button.dart';
import 'package:dineroo_mobile/shared/views/orders/order_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ManagerOrderTabReadyCard extends StatelessWidget {
  final Order order;
  final Contact? driver;
  final bool isLoadingDriver;

  const ManagerOrderTabReadyCard({
    super.key,
    required this.order,
    this.driver,
    this.isLoadingDriver = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    final hasDriver = driver != null && driver!.displayName.trim().isNotEmpty;
    final hasDriverPhone =
        driver?.phoneNumber != null && driver!.phoneNumber.trim().isNotEmpty;
    final driverImageUrl = driver?.imageUrl;

    final itemsCount = order.items.length;
    final itemsLabel = '$itemsCount article${itemsCount > 1 ? 's' : ''}';

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Remise de la commande',
                        style: TextStyle(
                          fontSize: isPortrait ? 14 : 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1C1C1E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: AppChip(
                          text: '#${order.shortId}',
                          backgroundColor: const Color(0xFFFFF1E6),
                          textColor: const Color(0xFFFD7E2F),
                          maxLines: 2,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: AppChip(
                          text: itemsLabel,
                          backgroundColor: const Color(0xFFF4F5F7),
                          textColor: const Color(0xFF8E8E93),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 140,
                    maxWidth: 180,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (isLoadingDriver)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: AppLoader(size: 24),
                        )
                      else if (hasDriver) ...[
                        Text(
                          'Livreur assigné',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                driver!.displayName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: isPortrait ? 12 : 11,
                                  color: const Color(0xFF8E8E93),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            AppAvatar(imageUrl: driverImageUrl, size: 32),
                            if (hasDriverPhone) ...[
                              const SizedBox(width: 8),
                              AppCallButton(
                                phoneNumber: driver!.phoneNumber,
                                size: 32,
                              ),
                            ],
                          ],
                        ),
                      ] else
                        const SizedBox.shrink(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OrderDetailButton(
                    orderId: order.id.toString(),
                    source: OrderSource.ready,
                    onTap: () async {
                      final didUpdateOrder = await navigateTo<bool>(
                        context,
                        OrderDetailView(
                          orderId: order.id.toString(),
                          source: OrderSource.ready,
                        ),
                      );
                      if (didUpdateOrder == true && context.mounted) {
                        try {
                          await context
                              .read<ManagerOrderListViewModel>()
                              .fetchOrdersByRestaurant(context);
                        } on ProviderNotFoundException {
                          // no provider in detail routes
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OrderGiveToDriverButton(
                    orderId: order.id.toString(),
                    shortId: order.shortId,
                    hasAssignedDriver: hasDriver,
                    isLoadingDriver: isLoadingDriver,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
