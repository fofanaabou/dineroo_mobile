import 'package:dineroo_mobile/manager/views/orders/ready/manager_order_tab_ready_card_loader.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dineroo_mobile/manager/view_models/orders/manager_order_list_view_model.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_empty_state.dart';
import 'package:dineroo_mobile/shared/enums/order_status.dart';

class ManagerOrdersTabReady extends StatelessWidget {
  const ManagerOrdersTabReady({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagerOrderListViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: AppLoader());
        }

        final readyOrders =
            viewModel.orders
                .where((o) => o.status == OrderStatus.readyForPickup)
                .toList()
              ..sort(
                (a, b) => viewModel
                    .effectiveLastModifiedDate(b)
                    .compareTo(viewModel.effectiveLastModifiedDate(a)),
              );

        if (readyOrders.isEmpty) {
          return const AppEmptyState(
            icon: Icons.inventory_2_outlined,
            message: 'Aucune commande pour le moment',
          );
        }

        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => viewModel.fetchOrdersByRestaurant(context),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 12, left: 8, right: 8),
                  itemCount: readyOrders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (ctx, i) {
                    final order = readyOrders[i];
                    return ManagerOrderTabReadyCardLoader(order: order);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
