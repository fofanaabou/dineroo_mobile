import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dineroo_mobile/customer/view_models/cart/cart_view_model.dart';
import 'package:dineroo_mobile/customer/views/cart/cart_view.dart';
import 'package:dineroo_mobile/shared/common/helpers/navigation_helper.dart';

class AppCartIcon extends StatelessWidget {
  final bool withBadge;
  final bool isClickable;
  final bool isForBottomNav;
  final double iconSize;
  final EdgeInsets badgePosition;

  const AppCartIcon({
    super.key,
    this.withBadge = true,
    this.isClickable = true,
    this.isForBottomNav = false,
    this.iconSize = 24,
    this.badgePosition = const EdgeInsets.only(top: 0, right: 0),
  });

  @override
  Widget build(BuildContext context) {
    final cartVM = context.watch<CartViewModel?>();
    final cartLength = cartVM?.groupedCarts.length ?? 0;

    final icon = SizedBox(
      width: iconSize + 8,
      height: iconSize + 8,
      child: Icon(Icons.shopping_cart_outlined, size: iconSize),
    );

    final badge = _buildBadge(cartLength);

    final content = Stack(
      alignment: Alignment.center,
      children: [icon, if (badge != null) badge],
    );

    if (isForBottomNav) return content;

    return IconButton(
      onPressed:
          isClickable
              ? () => navigateTo(context, const CartView(showBack: true))
              : null,
      icon: content,
    );
  }

  Widget? _buildBadge(int cartLength) {
    if (!withBadge || cartLength == 0) return null;

    return Positioned(
      right: badgePosition.right,
      top: badgePosition.top,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: Colors.deepOrange,
          shape: BoxShape.circle,
        ),
        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
        child: Text(
          '$cartLength',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
