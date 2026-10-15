import 'package:dineroo_mobile/shared/common/helpers/price_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_network_image.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_snackbar.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_quantity_selector.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:dineroo_mobile/customer/models/domain/cart_item.dart';
import 'package:dineroo_mobile/customer/models/domain/selected_menu_item.dart';
import 'package:dineroo_mobile/customer/view_models/cart/cart_view_model.dart';

class CartItemTile extends StatelessWidget {
  final CartItem item;
  final CartViewModel cartVM;

  const CartItemTile({super.key, required this.item, required this.cartVM});

  @override
  Widget build(BuildContext context) {
    final isUnavailable = cartVM.isUnavailableItem(item);
    final unavailableColor = Theme.of(context).colorScheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(isUnavailable ? 10 : 0),
      decoration: isUnavailable
          ? BoxDecoration(
              color: unavailableColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: unavailableColor.withValues(alpha: 0.35),
              ),
            )
          : null,
      child: Opacity(
        opacity: isUnavailable ? 0.72 : 1,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AppNetworkImage(
                imageUrl: item.product.imageUrl,
                width: 80,
                height: 80,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isUnavailable ? unavailableColor : null,
                    ),
                  ),
                  if (item.isConfiguredItem && item.selectedMenuItems != null)
                    ..._buildSelectedMenuItems(),
                  if (isUnavailable) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: unavailableColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Indisponible',
                        style: TextStyle(
                          color: unavailableColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              formatPrice(item.unitPrice),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isUnavailable ? unavailableColor : null,
                              ),
                            ),
                            if (item.isConfiguredItem &&
                                item.menuBasePrice != null)
                              Text(
                                '(${formatPrice(item.product.price)} + suppléments)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isUnavailable)
                        TextButton.icon(
                          onPressed: () => _removeItem(context),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Supprimer'),
                          style: TextButton.styleFrom(
                            foregroundColor: unavailableColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                      else
                        AppQuantitySelector(
                          quantity: item.quantity,
                          size: 12,
                          onAdd: () => cartVM.incrementItem(item),
                          onRemove: () {
                            if (item.quantity == 1) {
                              _showDeleteDialog(context);
                            } else {
                              cartVM.decrementQuantity(item);
                            }
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSelectedMenuItems() {
    if (item.selectedMenuItems == null || item.selectedMenuItems!.isEmpty) {
      return [];
    }

    final Map<String, List<SelectedMenuItem>> grouped = {};
    for (final sel in item.selectedMenuItems!) {
      grouped.putIfAbsent(sel.groupName, () => []).add(sel);
    }

    return grouped.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.key,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            ...entry.value.map(
              (sel) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sel.productName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (sel.productChoices != null)
                      ...sel.productChoices!.map(
                        (choice) => Padding(
                          padding: const EdgeInsets.only(left: 12, top: 1),
                          child: Text(
                            choice.itemName,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AppDialog(
        title: 'Supprimer l\'article',
        content: RichText(
          text: TextSpan(
            children: [
              const TextSpan(text: 'Souhaitez-vous vraiment supprimer '),
              TextSpan(
                text: '"${item.product.name}"',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' du panier ?'),
            ],
          ),
        ),
        confirmText: 'Supprimer',
        onConfirm: () {
          Navigator.of(context).pop();
          _removeItem(context);
        },
      ),
    );
  }

  void _removeItem(BuildContext context) {
    final quantity = item.quantity;
    cartVM.removeItem(item);
    AppSnackbar.warning(
      context,
      quantity > 1
          ? '$quantity x ${item.product.name} supprimés du panier'
          : '${item.product.name} supprimé du panier',
      bottomMargin: 80,
    );
  }
}
