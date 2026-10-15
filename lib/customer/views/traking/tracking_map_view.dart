import 'package:dineroo_mobile/customer/views/customer_main_view.dart';
import 'package:dineroo_mobile/customer/view_models/order/order_list_view_model.dart';
import 'package:dineroo_mobile/shared/common/helpers/navigation_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:dineroo_mobile/shared/enums/main_view_tabs.dart';
import 'package:dineroo_mobile/shared/views/map/map_view.dart';
import 'package:dineroo_mobile/customer/views/traking/tracking_card.dart';
import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_back_button.dart';
import 'package:dineroo_mobile/shared/common/factories/contact_factory.dart';
import 'package:dineroo_mobile/shared/repositories/order_details_repository.dart';
import 'package:dineroo_mobile/shared/services/order/order_details_service.dart';
import 'package:dineroo_mobile/shared/services/order/shared_order_service.dart';
import 'package:dineroo_mobile/shared/view_models/order/order_detail_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:provider/provider.dart';

class TrackingMapView extends StatelessWidget {
  final dynamic orderId;

  const TrackingMapView({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<CurrentUserViewModel>().currentUser;
    final orderListVM = context.read<OrderListViewModel>();

    return ChangeNotifierProvider(
      create:
          (_) {
        final vm = OrderDetailViewModel(
          sharedOrderService: SharedOrderService(),
          orderDetailsRepository: OrderDetailsRepository(
            service: OrderDetailsService(),
          ),
        );

        if (currentUser != null) {
          vm.initWithRealtime(
            orderId,
            currentUser.id,
            onOrderFetched: (order) => orderListVM.upsertOrder(order),
            onRealtimeEvent: (event) =>
                orderListVM.updateOrderStatusFromRealtime(event),
          );
        } else {
          vm.init(orderId);
        }

        return vm;
      },
      child: Consumer<OrderDetailViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading || vm.order == null) {
            return const Scaffold(body: Center(child: AppLoader()));
          }

          final order = vm.order!;
          final driver = vm.orderDetails?.driverDetails;

          final driverContact =
              driver != null
                  ? ContactFactory.publicDriver(
                    fullName: driver.fullName,
                    phoneNumber: driver.phoneNumber,
                  )
                  : null;

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop) {
                replaceAll(
                  context,
                  const CustomerMainView(
                    initialTab: CustomerMainViewTab.orders,
                  ),
                );
              }
            },
            child: Scaffold(
              body: Stack(
                children: [
                  const MapView(),
                  TrackingCard(order: order, driverContact: driverContact),
                  Positioned(
                    top: 50,
                    left: 16,
                    child: AppBackButton(
                      backgroundColor: Colors.white,
                      onPressed:
                          () => replaceAll(
                            context,
                            const CustomerMainView(
                              initialTab: CustomerMainViewTab.orders,
                            ),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
