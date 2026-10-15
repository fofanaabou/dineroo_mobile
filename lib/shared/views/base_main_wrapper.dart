import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/enums/main_view_tabs.dart';
import 'package:dineroo_mobile/customer/views/customer_main_view.dart';
import 'package:dineroo_mobile/driver/views/driver_main_view.dart';
import 'package:dineroo_mobile/manager/views/manager_main_view.dart';
import 'package:dineroo_mobile/shared/common/helpers/navigation_helper.dart';
import 'package:dineroo_mobile/shared/views/bottom_nav_bar.dart';

enum UserRole { customer, driver, manager }

class BaseMainWrapper extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  final UserRole role;

  const BaseMainWrapper({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: child,
      bottomNavigationBar: BottomNavBar(
        currentIndex: selectedIndex,
        onTap: (index) => _handleNavTap(context, role, index),
        items: _getNavItems(role),
      ),
    );
  }

  List<BottomNavigationBarItem> _getNavItems(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return CustomerMainView.bottomNavItems;
      case UserRole.driver:
        return DriverMainView.bottomNavItems;
      case UserRole.manager:
        return ManagerMainView.bottomNavItems;
    }
  }

  void _handleNavTap(BuildContext context, UserRole role, int index) {
    Widget destination;
    switch (role) {
      case UserRole.customer:
        destination = CustomerMainView(
          initialTab: CustomerMainViewTab.values[index],
        );
        break;
      case UserRole.driver:
        destination = DriverMainView(
          initialTab: DriverMainViewTab.values[index],
        );
        break;
      case UserRole.manager:
        destination = ManagerMainView(
          initialTab: ManagerMainViewTab.values[index],
        );
        break;
    }
    replaceAll(context, destination);
  }
}
