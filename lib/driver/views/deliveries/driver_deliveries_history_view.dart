import 'package:dineroo_mobile/customer/views/orders/order_list.dart';
import 'package:dineroo_mobile/driver/view_models/driver_order_history_view_model.dart';
import 'package:dineroo_mobile/driver/views/deliveries/delivery_card_footer/driver_delivery_history_footer.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_error_retry.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

part 'driver_deliveries_history_content.dart';

class DriverDeliveriesHistoryView extends StatefulWidget {
  const DriverDeliveriesHistoryView({super.key});

  @override
  State<DriverDeliveriesHistoryView> createState() =>
      _DriverDeliveriesHistoryViewState();
}

class _DriverDeliveriesHistoryViewState
    extends State<DriverDeliveriesHistoryView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DriverOrderHistoryViewModel>().fetchOrders();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<DriverOrderHistoryViewModel>().fetchOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Historique des livraisons',
      showCartIcon: false,
      body: const _DriverDeliveriesHistoryContent(),
    );
  }
}
