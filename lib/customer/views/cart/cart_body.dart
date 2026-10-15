import 'package:dineroo_mobile/customer/views/cart/grouped_cart_card.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_empty_state.dart';
import 'package:dineroo_mobile/customer/views/cart/grouped_cart_detail_view.dart';
import 'package:dineroo_mobile/customer/views/restaurant/detail/restaurant_detail_view.dart';
import 'package:dineroo_mobile/shared/common/helpers/navigation_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dineroo_mobile/customer/view_models/cart/cart_view_model.dart';

class CartBody extends StatefulWidget {
  const CartBody({super.key});

  @override
  State<CartBody> createState() => _CartBodyState();
}

class _CartBodyState extends State<CartBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CartViewModel>().refreshCartImages();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartViewModel>(
      builder: (context, cartVM, _) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildCartSection(context, cartVM),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartSection(BuildContext context, CartViewModel cartVM) {
    final groupedCarts = cartVM.groupedCarts;

    if (groupedCarts.isEmpty) {
      return const AppEmptyState(
        icon: Icons.shopping_cart_outlined,
        message: 'Votre panier est vide.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...groupedCarts.map(
          (group) => GroupedCartCard(
            group: group,
            onViewCart: () {
              navigateTo(context, GroupedCartDetailView(group: group));
            },
            onViewStore: () {
              navigateTo(
                context,
                RestaurantDetailView(restaurantId: group.restaurantId),
              );
            },
            onRemoveCartGroup: () {
              context.read<CartViewModel>().removeCartGroup(group.restaurantId);
            },
          ),
        ),
      ],
    );
  }
}
