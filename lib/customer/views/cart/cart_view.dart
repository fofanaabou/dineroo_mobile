import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_scaffold.dart';
import 'package:dineroo_mobile/customer/views/cart/cart_body.dart';
import 'package:dineroo_mobile/customer/views/cart/clear_cart_button.dart';
import 'package:dineroo_mobile/shared/views/base_main_wrapper.dart';
import 'package:dineroo_mobile/shared/enums/main_view_tabs.dart';

class CartView extends StatelessWidget {
  final bool showBack;

  const CartView({super.key, this.showBack = false});

  @override
  Widget build(BuildContext context) {
    final content = AppScaffold(
      title: 'Mon panier',
      showBack: showBack,
      showCartIcon: false,
      extraActions: const [ClearCartButton()],
      body: const SafeArea(child: Stack(children: [CartBody()])),
    );

    if (!showBack) {
      return content;
    }

    return BaseMainWrapper(
      role: UserRole.customer,
      selectedIndex: CustomerMainViewTab.cart.index,
      child: content,
    );
  }
}
