import 'package:dineroo_mobile/shared/models/domain/order.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_error_retry.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_empty_state.dart';
import 'package:flutter/material.dart';
import 'order_card.dart';

class OrderList extends StatelessWidget {
  final Future<List<Order>> future;
  final VoidCallback onRetry;
  final bool showRestaurantName;
  final bool hidePrice;
  final String emptyMessage;

  final Widget Function(Order order)? footerBuilder;

  const OrderList({
    super.key,
    required this.future,
    required this.onRetry,
    this.showRestaurantName = true,
    this.hidePrice = false,
    this.emptyMessage = 'Aucune commande à afficher',
    this.footerBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Order>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: AppLoader());
        }

        if (snapshot.hasError) {
          return AppErrorRetry(onPressed: onRetry);
        }

        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return AppEmptyState(icon: Icons.receipt_long, message: emptyMessage);
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final order = orders[index];
            return OrderCard(
              order: order,
              showRestaurantName: showRestaurantName,
              hidePrice: hidePrice,
              footer: footerBuilder?.call(order),
            );
          },
        );
      },
    );
  }
}
