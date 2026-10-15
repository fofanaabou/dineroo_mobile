import 'package:dineroo_mobile/manager/enums/order_source.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dineroo_mobile/customer/views/orders/order_list.dart';
import 'package:dineroo_mobile/manager/view_models/orders/manager_order_list_view_model.dart';
import 'package:dineroo_mobile/shared/common/helpers/navigation_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_empty_state.dart';
import 'package:dineroo_mobile/shared/enums/order_status.dart';
import 'package:dineroo_mobile/shared/views/orders/order_action_buttons/order_mark_ready_button.dart';
import 'package:dineroo_mobile/shared/views/orders/order_action_buttons/order_detail_button.dart';
import 'package:dineroo_mobile/shared/views/orders/order_detail_view.dart';

class ManagerOrdersTabOngoing extends StatelessWidget {
  const ManagerOrdersTabOngoing({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagerOrderListViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: AppLoader());
        }

        final ongoingOrders =
            viewModel.orders
                .where(
                  (o) =>
                      o.status == OrderStatus.accepted ||
                      o.status == OrderStatus.preparing,
                )
                .toList()
              ..sort((a, b) => a.createdDate.compareTo(b.createdDate));

        if (ongoingOrders.isEmpty) {
          return const AppEmptyState(
            icon: Icons.delivery_dining,
            message: 'Aucune commande pour le moment',
          );
        }

        return RefreshIndicator(
          onRefresh: () => viewModel.fetchOrdersByRestaurant(context),
          child: OrderList(
            future: Future.value(ongoingOrders),
            onRetry: () => viewModel.fetchOrdersByRestaurant(context),
            showRestaurantName: false,
            footerBuilder:
                (order) => Padding(
                  padding: const EdgeInsets.only(top: 12, left: 8, right: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: OrderDetailButton(
                          orderId: order.id.toString(),
                          source: OrderSource.ongoing,
                          onTap: () async {
                            final didUpdateOrder = await navigateTo<bool>(
                              context,
                              OrderDetailView(
                                orderId: order.id.toString(),
                                source: OrderSource.ongoing,
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
                        child: OrderMarkReadyButton(
                          orderId: order.id.toString(),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        );
      },
    );
  }
}
