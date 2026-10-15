import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_scaffold.dart';
import 'package:dineroo_mobile/customer/services/order/order_service.dart';
import 'package:dineroo_mobile/customer/services/order/order_list_service.dart';
import 'package:dineroo_mobile/customer/repositories/order_repository.dart';
import 'package:dineroo_mobile/customer/view_models/order/order_list_view_model.dart';
import 'package:dineroo_mobile/shared/services/order/shared_order_service.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'orders_tab_ongoing.dart';
import 'orders_tab_history.dart';

class OrdersView extends StatefulWidget {
  final int initialTabIndex;

  const OrdersView({super.key, this.initialTabIndex = 0});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late final OrderListViewModel _orderListViewModel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _orderListViewModel = OrderListViewModel(
      OrderRepository(
        orderService: OrderService(),
        listService: OrderListService(),
        sharedOrderService: SharedOrderService(),
      ),
      context.read<CurrentUserViewModel>(),
    );
    _orderListViewModel.fetchOrders(); // Initial load
  }

  @override
  void dispose() {
    _tabController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _orderListViewModel.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _orderListViewModel.fetchOrders(); // Refresh on app resume
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<OrderListViewModel>.value(
      value: _orderListViewModel,
      child: AppScaffold(
        title: 'Mes commandes',
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'En cours'), Tab(text: 'Historique')],
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [OrdersTabOngoing(), OrdersTabHistory()],
        ),
      ),
    );
  }
}
