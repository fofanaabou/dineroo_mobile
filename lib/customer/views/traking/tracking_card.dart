import 'package:dineroo_mobile/customer/views/traking/delivery_code_card.dart';
import 'package:dineroo_mobile/customer/services/restaurant/restaurant_info_cache_service.dart';
import 'package:dineroo_mobile/customer/views/traking/tracking_card_steps.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_contact_card.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_restaurant_name.dart';
import 'package:dineroo_mobile/shared/models/domain/contact.dart';
import 'package:dineroo_mobile/shared/models/domain/order.dart';
import 'package:flutter/material.dart';

class TrackingCard extends StatefulWidget {
  final Order order;
  final Contact? driverContact;

  const TrackingCard({super.key, required this.order, this.driverContact});

  @override
  State<TrackingCard> createState() => _TrackingCardState();
}

class _TrackingCardState extends State<TrackingCard> {
  final DraggableScrollableController _controller =
      DraggableScrollableController();

  bool _isCollapsed = false;
  late Future<String> _restaurantNameFuture;

  @override
  void initState() {
    super.initState();
    _restaurantNameFuture = RestaurantInfoCacheService.resolveRestaurantName(
      restaurantId: widget.order.restaurantId,
      restaurantName: widget.order.restaurantName,
    );
    _controller.addListener(_handleScroll);
  }

  @override
  void didUpdateWidget(covariant TrackingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.restaurantId != widget.order.restaurantId ||
        oldWidget.order.restaurantName != widget.order.restaurantName) {
      _restaurantNameFuture = RestaurantInfoCacheService.resolveRestaurantName(
        restaurantId: widget.order.restaurantId,
        restaurantName: widget.order.restaurantName,
      );
    }
  }

  void _handleScroll() {
    final collapsed = _controller.size <= 0.3;
    if (_isCollapsed != collapsed) {
      setState(() {
        _isCollapsed = collapsed;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleScroll);
    super.dispose();
  }

  void _toggleCardSize() async {
    final size = _controller.size;
    if (size > 0.3) {
      await _controller.animateTo(
        0.25,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      await _controller.animateTo(
        0.8,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final driverContact = widget.driverContact;
    final hasDriverContact =
        driverContact != null && driverContact.name.trim().isNotEmpty;

    return DraggableScrollableSheet(
      controller: _controller,
      initialChildSize: 0.8,
      minChildSize: 0.25,
      maxChildSize: 0.8,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _toggleCardSize,
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_isCollapsed) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          order.status.label,
                          style: const TextStyle(
                            color: Color(0xFFFF7643),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      DeliveryCodeCard(
                        compact: true,
                        status: order.status,
                        deliveryContactPhoneNumber:
                            order.deliveryContact.phoneNumber,
                      ),
                    ],
                  ),
                ),
                if (hasDriverContact) ...[
                  const SizedBox(height: 8),
                  AppContactCard(
                    contact: driverContact,
                    backgroundColor: Colors.transparent,
                    textColor: Colors.black,
                    subtitleColor: Colors.black54,
                  ),
                ],
              ] else ...[
                Text(
                  order.displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                  ),
                ),
                FutureBuilder<String>(
                  future: _restaurantNameFuture,
                  builder: (context, snapshot) {
                    final name = (snapshot.data ?? '').trim();
                    if (name.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: AppRestaurantName(name: name),
                    );
                  },
                ),
                const SizedBox(height: 16),
                DeliveryCodeCard(
                  status: order.status,
                  deliveryContactPhoneNumber: order.deliveryContact.phoneNumber,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Statut de la commande',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                TrackingCardSteps(
                  driverContact: hasDriverContact ? driverContact : null,
                  status: order.status,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
