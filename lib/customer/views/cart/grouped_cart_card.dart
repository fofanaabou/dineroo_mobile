import 'package:dineroo_mobile/customer/models/domain/cart_group.dart';
import 'package:dineroo_mobile/shared/common/helpers/price_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_network_image.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_button.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_dialog.dart';
import 'package:flutter/material.dart';

class GroupedCartCard extends StatelessWidget {
  final CartGroup group;
  final VoidCallback onViewCart;
  final VoidCallback onViewStore;
  final VoidCallback onRemoveCartGroup;

  const GroupedCartCard({
    super.key,
    required this.group,
    required this.onViewCart,
    required this.onViewStore,
    required this.onRemoveCartGroup,
  });

  void _confirmRemove(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Supprimer ce panier',
        message:
            'Voulez-vous vraiment supprimer le panier de ${group.restaurantName} ?',
        confirmText: 'Supprimer',
        onConfirm: () {
          Navigator.of(ctx).pop();
          onRemoveCartGroup();
        },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final restaurantName = group.restaurantName;
    final deliveryAddress = group.deliveryAddress.trim();
    final itemCount = group.items.length;
    final imageUrl = group.items.first.product.imageUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: AppNetworkImage(
                  imageUrl: imageUrl,
                  width: 48,
                  height: 48,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurantName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$itemCount élément${itemCount > 1 ? 's' : ''} • ${formatPrice(group.subtotal)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    if (deliveryAddress.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Livrer à l\'adresse : $deliveryAddress',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Supprimer ce panier',
                onPressed: () => _confirmRemove(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppButton(text: 'Voir le panier', onPressed: onViewCart),
          const SizedBox(height: 8),
          AppButton(
            text: 'Afficher l\'offre du restaurant',
            outlined: true,
            onPressed: onViewStore,
          ),
        ],
      ),
    );
  }
}
