import 'package:dineroo_mobile/customer/models/extensions/order_status_extensions.dart';
import 'package:dineroo_mobile/customer/view_models/order/order_list_view_model.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'order_list.dart';

class OrdersTabOngoing extends StatelessWidget {
  const OrdersTabOngoing({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderListViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: AppLoader());
        }

        final ongoingOrders = viewModel.orders
            .where((o) => o.status.isCustomerOngoing)
            .toList();

        return RefreshIndicator(
          onRefresh: viewModel.fetchOrders,
          child: OrderList(
            future: Future.value(ongoingOrders),
            onRetry: () => viewModel.fetchOrders(),
          ),
        );
      },
    );
  }
}
