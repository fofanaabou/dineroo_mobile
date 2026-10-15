import 'package:dineroo_mobile/manager/view_models/orders/manager_order_list_view_model.dart';
import 'package:dineroo_mobile/manager/services/manager_order_service.dart';
import 'package:dineroo_mobile/manager/repositories/manager_order_repository.dart';
import 'package:dineroo_mobile/manager/views/orders/ready/manager_order_tab_ready.dart';
import 'package:dineroo_mobile/manager/views/orders/manager_orders_tab_history.dart';
import 'package:dineroo_mobile/manager/views/orders/manager_orders_tab_ongoing.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ManagerOrdersView extends StatefulWidget {
  final int initialTabIndex;

  const ManagerOrdersView({super.key, this.initialTabIndex = 0});

  @override
  State<ManagerOrdersView> createState() => _ManagerOrdersViewState();
}

class _ManagerOrdersViewState extends State<ManagerOrdersView>
    with WidgetsBindingObserver {
  late final ManagerOrderListViewModel _orderListViewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _orderListViewModel = ManagerOrderListViewModel(
      ManagerOrderRepository(service: ManagerOrderService()),
    );
    _orderListViewModel.fetchOrdersByRestaurant(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _orderListViewModel.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _orderListViewModel.fetchOrdersByRestaurant(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ManagerOrderListViewModel>.value(
      value: _orderListViewModel,
      child: DefaultTabController(
        length: 3,
        initialIndex: widget.initialTabIndex,
        child: Builder(
          builder: (context) {
            return const AppScaffold(
              title: 'Espace commandes',
              showCartIcon: false,
              bottom: TabBar(
                tabs: [
                  Tab(text: 'Préparation'),
                  Tab(text: 'Prêtes'),
                  Tab(text: 'Historiques'),
                ],
              ),
              body: TabBarView(
                children: [
                  ManagerOrdersTabOngoing(),
                  ManagerOrdersTabReady(),
                  ManagerOrdersTabHistory(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
