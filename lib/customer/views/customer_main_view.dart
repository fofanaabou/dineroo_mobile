import 'package:dineroo_mobile/customer/views/orders/orders_view.dart';
import 'package:dineroo_mobile/shared/enums/main_view_tabs.dart';
import 'package:dineroo_mobile/shared/views/base_main_view.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_cart_icon.dart';
import 'package:flutter/material.dart';
import 'package:dineroo_mobile/customer/views/restaurant/list/restaurant_list_view.dart';
import 'package:dineroo_mobile/customer/views/wallet/customer_wallet_view.dart';
import 'package:dineroo_mobile/shared/common/helpers/navigation_helper.dart';
import 'package:dineroo_mobile/shared/views/profile/profile_content_tile.dart';
import 'package:dineroo_mobile/shared/views/profile/profile_view.dart';
import 'package:dineroo_mobile/customer/views/cart/cart_view.dart';

class CustomerMainView extends StatelessWidget {
  final CustomerMainViewTab initialTab;
  final int initialOrdersTabIndex;

  const CustomerMainView({
    super.key,
    this.initialTab = CustomerMainViewTab.home,
    this.initialOrdersTabIndex = 0,
  });

  static List<BottomNavigationBarItem> get bottomNavItems => const [
    BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Accueil'),
    BottomNavigationBarItem(
      icon: AppCartIcon(isForBottomNav: true, isClickable: false),
      label: 'Panier',
    ),
    BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Commandes'),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return BaseMainView(
      initialIndex: initialTab.index,
      navItems: CustomerMainView.bottomNavItems,
      screenBuilder: (index) {
        switch (CustomerMainViewTab.values[index]) {
          case CustomerMainViewTab.home:
            return const RestaurantListView();
          case CustomerMainViewTab.orders:
            return OrdersView(initialTabIndex: initialOrdersTabIndex);
          case CustomerMainViewTab.cart:
            return const CartView();
          case CustomerMainViewTab.profile:
            return ProfileView(
              actionTiles: [
                ProfileContentTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Mon Wallet',
                  onTap: () => navigateTo(context, const CustomerWalletView()),
                ),
                const Divider(height: 1, color: Color(0xFFEAEAEA)),
              ],
            );
        }
      },
    );
  }
}
