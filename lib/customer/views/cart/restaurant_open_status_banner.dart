import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dineroo_mobile/customer/view_models/restaurant/restaurant_view_model.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';

class RestaurantOpenStatusBanner extends StatefulWidget {
  final String restaurantId;

  const RestaurantOpenStatusBanner({super.key, required this.restaurantId});

  @override
  State<RestaurantOpenStatusBanner> createState() =>
      _RestaurantOpenStatusBannerState();
}

class _RestaurantOpenStatusBannerState
    extends State<RestaurantOpenStatusBanner> {
  late Future<bool> _future;

  @override
  void initState() {
    super.initState();
    final vm = context.read<RestaurantViewModel>();
    _future = vm.restaurantIsOpen(widget.restaurantId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: AppLoader(
                    size: 22,
                    strokeWidth: 2,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Vérification des horaires…',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                ),
              ],
            ),
          );
        }

        final isRestaurantOpen = snapshot.data ?? true;
        if (snapshot.hasError || isRestaurantOpen) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Ce restaurant est actuellement fermé.\n'
                  'Vous ne pouvez plus finaliser cette commande.',
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
