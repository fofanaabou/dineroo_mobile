import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dineroo_mobile/shared/models/domain/contact.dart';
import 'package:dineroo_mobile/shared/models/domain/order.dart';
import 'package:dineroo_mobile/shared/repositories/order_details_repository.dart';
import 'package:dineroo_mobile/shared/services/order/order_details_service.dart';
import 'package:dineroo_mobile/manager/view_models/orders/manager_order_ready_card_view_model.dart';
import 'package:dineroo_mobile/manager/views/orders/ready/manager_order_tab_ready_card.dart';

class ManagerOrderTabReadyCardLoader extends StatelessWidget {
  final Order order;

  const ManagerOrderTabReadyCardLoader({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) => ManagerOrderReadyCardViewModel(
            OrderDetailsRepository(service: OrderDetailsService()),
          )..init(order.id.toString()),
      child: Consumer<ManagerOrderReadyCardViewModel>(
        builder: (context, vm, _) {
          final driver = vm.orderDetails?.driverDetails;

          return ManagerOrderTabReadyCard(
            order: order,
            driver:
                driver != null
                    ? Contact(
                      name: driver.fullName,
                      phoneNumber: driver.phoneNumber,
                    )
                    : null,
            isLoadingDriver: vm.isLoading,
          );
        },
      ),
    );
  }
}
