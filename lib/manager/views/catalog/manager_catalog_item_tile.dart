import 'package:dineroo_mobile/customer/models/domain/product.dart';
import 'package:dineroo_mobile/shared/common/helpers/price_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_network_image.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_switch.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_snackbar.dart';
import 'package:dineroo_mobile/manager/view_models/catalog/manager_catalog_products_view_model.dart';
import 'package:dineroo_mobile/manager/view_models/catalog/manager_catalog_menus_view_model.dart';

class ManagerCatalogItemTile extends StatefulWidget {
  final String restaurantId;
  final dynamic item;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ManagerCatalogItemTile({
    super.key,
    required this.restaurantId,
    required this.item,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<ManagerCatalogItemTile> createState() => _ManagerCatalogItemTileState();
}

class _ManagerCatalogItemTileState extends State<ManagerCatalogItemTile> {
  bool _isLoading = false;
  Future<void> _handleAvailabilityToggle(BuildContext context) async {
    setState(() => _isLoading = true);
    bool success = false;
    final isProduct = widget.item is Product;
    final itemId = widget.item.id;
    final restaurantId = widget.restaurantId;
    try {
      if (isProduct) {
        success = await context
            .read<ManagerCatalogProductsViewModel>()
            .toggleAvailability(restaurantId, itemId);
      } else {
        success = await context
            .read<ManagerCatalogMenusViewModel>()
            .toggleAvailability(restaurantId, itemId);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (!context.mounted) return;
    if (success) {
      AppSnackbar.success(
        context,
        '${isProduct ? 'Produit' : 'Menu'} mis à jour avec succès.',
      );
    } else {
      AppSnackbar.error(
        context,
        'Erreur lors de la mise à jour du ${isProduct ? 'produit' : 'menu'}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return ListTile(
      onTap: widget.onTap,
      leading: AppNetworkImage(
        imageUrl: item.imageUrl,
        width: 48,
        height: 48,
        borderRadius: 8,
      ),
      title: Text(item.name),
      subtitle: Text(formatPrice(item.price)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(item.available ? 'Disponible' : 'Indisponible'),
          const SizedBox(width: 8),
          AppSwitch(
            value: item.available,
            isLoading: _isLoading,
            onChanged: (_) => _handleAvailabilityToggle(context),
          ),
          if (widget.onEdit != null || widget.onDelete != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  widget.onEdit?.call();
                } else if (value == 'delete') {
                  widget.onDelete?.call();
                }
              },
              itemBuilder: (_) => [
                if (widget.onEdit != null)
                  const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                if (widget.onDelete != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Supprimer'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
