import 'package:dineroo_mobile/customer/models/domain/product_choice_item.dart';
import 'package:dineroo_mobile/customer/models/domain/selected_menu_item.dart';
import 'package:dineroo_mobile/customer/views/restaurant/product_detail_view.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_add_button.dart';
import 'package:dineroo_mobile/customer/models/domain/restaurant.dart';
import 'package:dineroo_mobile/customer/view_models/cart/cart_view_model.dart';
import 'package:dineroo_mobile/shared/common/helpers/price_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_unavailable_overlay.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_network_image.dart';
import 'package:dineroo_mobile/customer/models/domain/product.dart';
import 'package:provider/provider.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final Restaurant restaurant;

  const ProductCard({
    super.key,
    required this.product,
    required this.restaurant,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = product.available;
    final isConfigurable = product.choiceGroups.isNotEmpty;

    return Opacity(
      opacity: isAvailable ? 1.0 : 0.5,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFDFDFD),
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: isConfigurable && isAvailable
              ? () => _openConfigSheet(context)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      AppNetworkImage(
                        imageUrl: product.imageUrl,
                        width: 92,
                        height: 92,
                        borderRadius: 0,
                        fit: BoxFit.cover,
                      ),
                      if (!isAvailable)
                        const AppUnavailableOverlay(
                          badgeAlignment: Alignment.topCenter,
                          badgeMargin: EdgeInsets.only(top: 8),
                          badgePadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          fontSize: 7,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                          _AddToCartButton(
                            product: product,
                            restaurant: restaurant,
                            isAvailable: isAvailable,
                          ),
                        ],
                      ),
                      if (product.description.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          product.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black54,
                            height: 1.3,
                          ),
                        ),
                      ],
                      const SizedBox(height: 5),
                      Text(
                        formatPrice(product.price),
                        style: const TextStyle(
                          color: Color(0xFF5F5448),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openConfigSheet(BuildContext context) async {
    final choices = await showModalBottomSheet<List<ProductChoiceItem>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductDetailView(
        restaurantId: restaurant.id,
        productId: product.id,
        productName: product.name,
        productImageUrl: product.imageUrl,
      ),
    );
    if (choices == null) return;

    if (!context.mounted) return;
    Provider.of<CartViewModel>(context, listen: false).addConfiguredProduct(
      product: product,
      selectedItems: _toSelectedItems(choices),
      basePrice: product.price,
      restaurantId: restaurant.id,
      restaurantName: restaurant.name,
    );

    AppSnackbar.success(
      context,
      'Ajouté au panier avec succès',
      duration: const Duration(seconds: 1),
    );
  }

  List<SelectedMenuItem> _toSelectedItems(List<ProductChoiceItem> choices) {
    return choices
        .expand(
          (choice) => List.generate(
            choice.quantity,
            (_) => SelectedMenuItem(
              groupId: choice.groupId,
              groupName: choice.groupName,
              menuItemId: choice.itemId,
              productId: choice.itemId,
              productName: choice.itemName,
              additionalPrice: choice.additionalPrice,
            ),
          ),
        )
        .toList();
  }
}

class _AddToCartButton extends StatefulWidget {
  final Product product;
  final Restaurant restaurant;
  final bool isAvailable;

  const _AddToCartButton({
    required this.product,
    required this.restaurant,
    required this.isAvailable,
  });

  @override
  State<_AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<_AddToCartButton> {
  bool _added = false;

  Future<void> _onTap() async {
    if (_added) return;

    final cart = context.read<CartViewModel>();
    if (widget.product.choiceGroups.isNotEmpty) {
      final choices = await showModalBottomSheet<List<ProductChoiceItem>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ProductDetailView(
          restaurantId: widget.restaurant.id,
          productId: widget.product.id,
          productName: widget.product.name,
          productImageUrl: widget.product.imageUrl,
        ),
      );
      if (choices == null) return;

      if (!context.mounted) return;
      cart.addConfiguredProduct(
        product: widget.product,
        selectedItems: _toSelectedItems(choices),
        basePrice: widget.product.price,
        restaurantId: widget.restaurant.id,
        restaurantName: widget.restaurant.name,
      );
    } else {
      cart.addProduct(
        widget.product,
        restaurantId: widget.restaurant.id,
        restaurantName: widget.restaurant.name,
      );
    }

    if (!mounted) return;
    setState(() => _added = true);

    AppSnackbar.success(
      context,
      'Ajouté au panier avec succès',
      duration: const Duration(seconds: 1),
    );

    await Future.delayed(const Duration(milliseconds: 1200));

    if (mounted) setState(() => _added = false);
  }

  List<SelectedMenuItem> _toSelectedItems(List<ProductChoiceItem> choices) {
    return choices
        .expand(
          (choice) => List.generate(
            choice.quantity,
            (_) => SelectedMenuItem(
              groupId: choice.groupId,
              groupName: choice.groupName,
              menuItemId: choice.itemId,
              productId: choice.itemId,
              productName: choice.itemName,
              additionalPrice: choice.additionalPrice,
            ),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_added) {
      return SizedBox(
        width: 36,
        height: 36,
        child: Material(
          color: Colors.green,
          shape: const CircleBorder(),
          child: const Icon(Icons.check, color: Colors.white, size: 20),
        ),
      );
    }

    return AppAddButton(onTap: widget.isAvailable ? _onTap : null);
  }
}
