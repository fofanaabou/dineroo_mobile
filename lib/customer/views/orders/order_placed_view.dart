import 'package:dineroo_mobile/customer/views/customer_main_view.dart';
import 'package:flutter/material.dart';
import 'package:dineroo_mobile/customer/services/restaurant/restaurant_info_cache_service.dart';
import 'package:dineroo_mobile/shared/common/helpers/navigation_helper.dart';
import 'package:dineroo_mobile/customer/views/traking/tracking_map_view.dart';
import 'package:dineroo_mobile/shared/models/domain/order.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_button.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_restaurant_name.dart';
import 'package:dineroo_mobile/shared/views/base_main_wrapper.dart';
import 'package:dineroo_mobile/shared/enums/main_view_tabs.dart';

class OrderPlacedView extends StatefulWidget {
  final Order order;

  const OrderPlacedView({super.key, required this.order});

  @override
  State<OrderPlacedView> createState() => _OrderPlacedViewState();
}

class _OrderPlacedViewState extends State<OrderPlacedView> {
  late final Future<String> _restaurantNameFuture;

  @override
  void initState() {
    super.initState();
    _restaurantNameFuture = RestaurantInfoCacheService.resolveRestaurantName(
      restaurantId: widget.order.restaurantId,
      restaurantName: widget.order.restaurantName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final content = Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Commande passée !',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<String>(
                  future: _restaurantNameFuture,
                  builder: (context, snapshot) {
                    final name = (snapshot.data ?? '').trim();
                    if (name.isEmpty) return const SizedBox.shrink();
                    return Column(
                      children: [
                        AppRestaurantName(name: name, centered: true),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                ),
                const Text(
                  'Votre commande a été passée avec succès. \nUn livreur sera assigné et vous recevrez les détails sous peu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Color(0xFF9F9F9F)),
                ),
                const SizedBox(height: 60),
                Image.asset(
                  'assets/images/order_placed_image.png',
                  width: 98,
                  height: 98,
                  color: Colors.greenAccent,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text('Erreur de chargement image');
                  },
                ),
                const SizedBox(height: 60),
                AppButton(
                  text: 'Suivre la commande',
                  onPressed: () {
                    replaceAll(context, TrackingMapView(orderId: order.id));
                  },
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: 'Retour à l’accueil',
                  outlined: true,
                  onPressed: () {
                    replaceAll(
                      context,
                      const CustomerMainView(
                        initialTab: CustomerMainViewTab.home,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return BaseMainWrapper(
      role: UserRole.customer,
      selectedIndex: CustomerMainViewTab.orders.index,
      child: content,
    );
  }
}
