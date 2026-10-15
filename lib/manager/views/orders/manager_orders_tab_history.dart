import 'package:dineroo_mobile/manager/enums/order_source.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_empty_state.dart';
import 'package:dineroo_mobile/shared/views/orders/order_action_buttons/order_detail_button.dart';
import 'package:dineroo_mobile/customer/views/orders/order_list.dart';
import 'package:dineroo_mobile/manager/view_models/orders/manager_order_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ManagerOrdersTabHistory extends StatelessWidget {
  const ManagerOrdersTabHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagerOrderListViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: AppLoader());
        }

        final historyOrders =
            viewModel.orders.where((o) => o.status.isHistory).toList()..sort(
              (a, b) => viewModel
                  .effectiveLastModifiedDate(b)
                  .compareTo(viewModel.effectiveLastModifiedDate(a)),
            );

        if (historyOrders.isEmpty) {
          return const AppEmptyState(
            icon: Icons.history,
            message: 'Aucune commande pour le moment',
          );
        }

        return RefreshIndicator(
          onRefresh: () => viewModel.fetchOrdersByRestaurant(context),
          child: OrderList(
            future: Future.value(historyOrders),
            onRetry: () => viewModel.fetchOrdersByRestaurant(context),
            showRestaurantName: false,
            footerBuilder:
                (order) => Padding(
                  padding: const EdgeInsets.only(top: 12, left: 8, right: 8),
                  child: OrderDetailButton(
                    orderId: order.id.toString(),
                    source: OrderSource.history,
                  ),
                ),
          ),
        );
      },
    );
  }
}
