import 'package:dineroo_mobile/manager/repositories/manager_products_repository.dart';
import 'package:dineroo_mobile/manager/services/manager_products_service.dart';
import 'package:dineroo_mobile/manager/view_models/catalog/manager_catalog_products_view_model.dart';
import 'package:dineroo_mobile/manager/view_models/catalog/manager_catalog_menus_view_model.dart';
import 'package:dineroo_mobile/manager/views/home/manager_home_view.dart';
import 'package:dineroo_mobile/manager/views/catalog/manager_catalog_view.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:dineroo_mobile/manager/services/manager_menus_service.dart';
import 'package:dineroo_mobile/manager/repositories/manager_menus_repository.dart';
import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/common/utils/wakelock_utils.dart';
import 'package:dineroo_mobile/shared/views/base_main_view.dart';
import 'package:dineroo_mobile/shared/views/profile/profile_view.dart';
import 'package:dineroo_mobile/shared/enums/main_view_tabs.dart';
import 'orders/manager_orders_view.dart';
import 'package:dineroo_mobile/shared/gain/gain_view.dart';
import 'package:provider/provider.dart';

class ManagerMainView extends StatefulWidget {
  final ManagerMainViewTab initialTab;
  final int initialOrdersTabIndex;

  const ManagerMainView({
    super.key,
    this.initialTab = ManagerMainViewTab.home,
    this.initialOrdersTabIndex = 0,
  });

  static List<BottomNavigationBarItem> get bottomNavItems => const [
    BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Accueil'),
    BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Commandes'),
    BottomNavigationBarItem(
      icon: Icon(Icons.trending_up_outlined),
      label: 'Gains',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.inventory_2_outlined),
      label: 'Catalogue',
    ),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
  ];

  @override
  State<ManagerMainView> createState() => _ManagerMainViewState();
}

class _ManagerMainViewState extends State<ManagerMainView>
    with WidgetsBindingObserver {
  late int _ordersTabIndex;

  @override
  void initState() {
    super.initState();
    _ordersTabIndex = widget.initialOrdersTabIndex;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => WakeLockUtils.enable());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakeLockUtils.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        WakeLockUtils.enable();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        WakeLockUtils.disable();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseMainView(
      initialIndex: widget.initialTab.index,
      navItems: ManagerMainView.bottomNavItems,
      screenBuilder: (index) {
        switch (ManagerMainViewTab.values[index]) {
          case ManagerMainViewTab.home:
            return ManagerHomeView(
              onOpenOrdersTab: (homeContext, tabIndex) {
                _ordersTabIndex = tabIndex;
                BaseMainView.switchTo(
                  homeContext,
                  ManagerMainViewTab.orders.index,
                  rebuild: true,
                  addToHistory: true,
                );
              },
            );
          case ManagerMainViewTab.orders:
            return ManagerOrdersView(initialTabIndex: _ordersTabIndex);
          case ManagerMainViewTab.earnings:
            return const GainView();
          case ManagerMainViewTab.catalog:
            final restaurantId =
                context
                    .read<CurrentUserViewModel>()
                    .currentUser
                    ?.organization
                    ?.id ??
                '';
            return MultiProvider(
              providers: [
                ChangeNotifierProvider(
                  create: (_) => ManagerCatalogMenusViewModel(
                    ManagerMenusRepository(service: ManagerMenusService()),
                  )..fetchMenus(restaurantId),
                ),
                ChangeNotifierProvider(
                  create: (_) => ManagerCatalogProductsViewModel(
                    ManagerProductsRepository(
                      service: ManagerProductsService(),
                    ),
                  )..fetchProducts(restaurantId),
                ),
              ],
              child: ManagerCatalogView(restaurantId: restaurantId),
            );
          case ManagerMainViewTab.profile:
            return const ProfileView();
        }
      },
    );
  }
}
