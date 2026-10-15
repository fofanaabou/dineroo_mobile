import 'package:dineroo_mobile/customer/views/orders/order_card_content.dart';
import 'package:dineroo_mobile/customer/views/orders/order_card_status.dart';
import 'package:dineroo_mobile/customer/views/traking/tracking_map_view.dart';
import 'package:dineroo_mobile/customer/services/restaurant/restaurant_info_cache_service.dart';
import 'package:dineroo_mobile/shared/common/helpers/navigation_helper.dart';
import 'package:dineroo_mobile/shared/common/utils/date_utils.dart';
import 'package:dineroo_mobile/shared/models/domain/order.dart';
import 'package:dineroo_mobile/shared/views/orders/order_action_buttons/order_detail_button.dart';
import 'package:dineroo_mobile/shared/views/orders/order_action_buttons/order_track_button.dart';
import 'package:flutter/material.dart';

class OrderCard extends StatefulWidget {
  final Order order;
  final Widget? footer;
  final bool showRestaurantName;
  final bool hidePrice;

  const OrderCard({
    super.key,
    required this.order,
    this.footer,
    this.showRestaurantName = true,
    this.hidePrice = false,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  late Future<String> _restaurantNameFuture;

  @override
  void initState() {
    super.initState();
    _restaurantNameFuture = _restaurantName();
  }

  @override
  void didUpdateWidget(OrderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.restaurantId != widget.order.restaurantId ||
        oldWidget.order.restaurantName != widget.order.restaurantName ||
        oldWidget.showRestaurantName != widget.showRestaurantName) {
      _restaurantNameFuture = _restaurantName();
    }
  }

  Future<String> _restaurantName() {
    if (!widget.showRestaurantName) return Future.value('');

    return RestaurantInfoCacheService.resolveRestaurantName(
      restaurantId: widget.order.restaurantId,
      restaurantName: widget.order.restaurantName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerTotalPrice =
        widget.order.totalPrice +
        (widget.order.deliveryFee ?? 0) +
        (widget.order.serviceFee ?? 0);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade100),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OrderCardStatus(status: widget.order.status),
            const SizedBox(height: 8),
            FutureBuilder<String>(
              future: _restaurantNameFuture,
              builder: (context, snapshot) {
                return OrderCardContent(
                  imageUrl: widget.order.items.isNotEmpty
                      ? widget.order.items.first.imageUrl
                      : '',
                  title: widget.order.displayName,
                  restaurantName: snapshot.data,
                  price: customerTotalPrice,
                  itemsCount: widget.order.items.length,
                  date: formatDateTime(widget.order.createdDate),
                  hidePrice: widget.hidePrice,
                );
              },
            ),
            const SizedBox(height: 12),
            if (widget.footer != null) widget.footer!,
            if (widget.footer == null) ...[
              if (widget.order.status.isOngoing)
                Row(
                  children: [
                    Expanded(
                      child: OrderDetailButton(orderId: widget.order.id),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OrderTrackButton(
                        orderId: widget.order.id,
                        onTap: () => navigateTo(
                          context,
                          TrackingMapView(orderId: widget.order.id),
                        ),
                      ),
                    ),
                  ],
                )
              else
                OrderDetailButton(orderId: widget.order.id),
            ],
          ],
        ),
      ),
    );
  }
}
