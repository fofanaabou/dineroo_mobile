import 'package:dineroo_mobile/customer/views/cart/cart_payment_button.dart';
import 'package:dineroo_mobile/shared/common/helpers/price_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:flutter/material.dart';
import 'package:dineroo_mobile/customer/models/domain/cart_group.dart';
import 'package:provider/provider.dart';
import 'package:dineroo_mobile/customer/view_models/cart/cart_view_model.dart';

class CartBottomBar extends StatelessWidget {
  final CartGroup group;

  const CartBottomBar({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final cartVM = context.watch<CartViewModel>();
    final total = cartVM.totalFor(group);
    final isEstimating = cartVM.isEstimating(group.restaurantId);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  total == null
                      ? (isEstimating ? '' : 'Estimation indisponible')
                      : formatPrice(total),
                  style: TextStyle(
                    fontSize: total == null ? 15 : 18,
                    fontWeight: FontWeight.bold,
                    color: total == null ? const Color(0xFF666666) : null,
                  ),
                ),
                if (isEstimating)
                  const Row(
                    children: [
                      AppLoader(size: 10, strokeWidth: 2),
                      SizedBox(width: 6),
                      Text(
                        'Calcul des frais en cours...',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
              ],
            ),
            CartPaymentButton(group: group, width: 140),
          ],
        ),
      ),
    );
  }
}
