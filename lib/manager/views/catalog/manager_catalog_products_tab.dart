import 'package:dineroo_mobile/manager/view_models/catalog/manager_catalog_products_view_model.dart';
import 'package:dineroo_mobile/customer/models/domain/product.dart';
import 'package:dineroo_mobile/manager/views/manager_suspension_notice.dart';
import 'package:dineroo_mobile/shared/exceptions/restaurant_suspended_exception.dart';
import 'package:dineroo_mobile/shared/common/helpers/price_helper.dart';
import 'package:dineroo_mobile/shared/common/utils/text_utils.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_empty_state.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_error_retry.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_info_pill.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_network_image.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_dialog.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_switch.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ManagerCatalogProductsTab extends StatelessWidget {
  final String restaurantId;
  final bool isSuspended;

  const ManagerCatalogProductsTab({
    super.key,
    required this.restaurantId,
    this.isSuspended = false,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ManagerCatalogProductsViewModel>();

    if (vm.isLoading) {
      return const Center(child: AppLoader());
    }
    if (vm.hasError) {
      return AppErrorRetry(
        message: 'Impossible de charger les produits.',
        onPressed: () => vm.fetchProducts(restaurantId),
      );
    }
    if (vm.products.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => vm.fetchProducts(restaurantId),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: constraints.maxHeight,
                  child: const AppEmptyState(
                    icon: Icons.restaurant,
                    message:
                        'Aucun produit disponible. Contactez Dineroo pour importer votre catalogue.',
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => vm.fetchProducts(restaurantId),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: vm.products.length,
        itemBuilder: (_, i) {
          final product = vm.products[i];
          return ManagerProductCard(
            restaurantId: restaurantId,
            product: product,
            isSuspended: isSuspended,
          );
        },
      ),
    );
  }
}

class ManagerProductCard extends StatefulWidget {
  final String restaurantId;
  final Product product;
  final bool isSuspended;
  final bool highlightUnavailable;
  final VoidCallback? onAvailabilityChange;

  const ManagerProductCard({
    super.key,
    required this.restaurantId,
    required this.product,
    this.isSuspended = false,
    this.highlightUnavailable = false,
    this.onAvailabilityChange,
  });

  @override
  State<ManagerProductCard> createState() => _ManagerProductCardState();
}

class _ManagerProductCardState extends State<ManagerProductCard> {
  bool _isLoading = false;

  Future<void> _toggleAvailability() async {
    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: widget.product.available
            ? 'Rendre ce produit indisponible ?'
            : 'Rendre ce produit disponible ?',
        content: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppDialog.defaultContentStyle,
            children: [
              TextSpan(
                text: widget.product.name,
                style: AppDialog.defaultContentStyle.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: widget.product.available
                    ? ' ne sera plus disponible seul. S’il est utilisé dans un menu, il ne pourra plus être sélectionné.'
                    : ' sera de nouveau disponible seul. S’il est utilisé dans un menu, il pourra à nouveau être sélectionné.',
              ),
            ],
          ),
        ),
        cancelText: 'Annuler',
        confirmText: 'Confirmer',
        onCancel: () => Navigator.pop(context, false),
        onConfirm: () => Navigator.pop(context, true),
      ),
    );
    if (shouldContinue != true) return;
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      final success = await context
          .read<ManagerCatalogProductsViewModel>()
          .toggleAvailability(widget.restaurantId, widget.product.id);
      if (!mounted) return;

      final availabilityCallback = widget.onAvailabilityChange;

      if (success) {
        availabilityCallback?.call();
        if (availabilityCallback == null) {
          AppSnackbar.success(context, 'Produit mis à jour avec succès.');
        }
      } else {
        AppSnackbar.error(context, 'Erreur lors de la mise à jour du produit.');
      }
    } on RestaurantSuspendedException {
      if (!mounted) return;
      await ManagerSuspensionNotice.showServerRefusalAndReloadRestaurant(
        context,
        restaurantId: widget.restaurantId,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.highlightUnavailable
            ? const Color(0xFFFFF7F5)
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.highlightUnavailable
              ? const Color(0xFFFFD8CE)
              : const Color(0xFFECECEC),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppNetworkImage(
                imageUrl: product.imageUrl,
                width: 72,
                height: 72,
                borderRadius: 18,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    if (product.description.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        product.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black54),
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
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    AppInfoPill(
                      label: capitalize(product.category),
                      color: Colors.black87,
                      icon: Icons.category_outlined,
                    ),
                    AppInfoPill(
                      label: 'Vendu à l’unité',
                      color: Colors.green,
                      backgroundColor: Colors.green.withValues(alpha: 0.08),
                      icon: Icons.shopping_bag_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AppSwitch(
                value: product.available,
                isLoading: _isLoading,
                isDisabled: widget.isSuspended,
                onDisabledTap: () =>
                    ManagerSuspensionNotice.showLockedAction(context),
                onChanged: (_) => _toggleAvailability(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
