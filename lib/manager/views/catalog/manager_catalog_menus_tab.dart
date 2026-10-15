import 'package:dineroo_mobile/manager/view_models/catalog/manager_catalog_menus_view_model.dart';
import 'package:dineroo_mobile/manager/views/catalog/manager_catalog_menu_detail_view.dart';
import 'package:dineroo_mobile/manager/views/catalog/manager_catalog_stats_view.dart';
import 'package:dineroo_mobile/manager/views/manager_suspension_notice.dart';
import 'package:dineroo_mobile/shared/exceptions/restaurant_suspended_exception.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_empty_state.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_error_retry.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_info_pill.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_network_image.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_dialog.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_switch.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_snackbar.dart';
import 'package:dineroo_mobile/shared/common/helpers/price_helper.dart';
import 'package:dineroo_mobile/shared/models/domain/menu.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ManagerCatalogMenusTab extends StatelessWidget {
  final String restaurantId;
  final bool isSuspended;

  const ManagerCatalogMenusTab({
    super.key,
    required this.restaurantId,
    this.isSuspended = false,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ManagerCatalogMenusViewModel>();

    if (vm.isLoading) {
      return const Center(child: AppLoader());
    }
    if (vm.hasError) {
      return AppErrorRetry(
        message: 'Impossible de charger les menus.',
        onPressed: () => vm.fetchMenus(restaurantId),
      );
    }
    if (vm.menus.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => vm.fetchMenus(restaurantId),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: constraints.maxHeight,
                  child: const AppEmptyState(
                    icon: Icons.menu_book_outlined,
                    message:
                        'Aucun menu disponible. Contactez Dineroo pour importer votre catalogue.',
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => vm.fetchMenus(restaurantId),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: vm.menus.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) return const ManagerCatalogStatsEntry();
          final menu = vm.menus[i - 1];
          return ManagerMenuCard(
            restaurantId: restaurantId,
            menu: menu,
            isSuspended: isSuspended,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ManagerCatalogMenuDetailView(
                    restaurantId: restaurantId,
                    menuId: menu.id,
                    menuName: menu.name,
                    isSuspended: isSuspended,
                  ),
                ),
              ).then((_) => vm.fetchMenus(restaurantId));
            },
          );
        },
      ),
    );
  }
}

class ManagerMenuCard extends StatefulWidget {
  final String restaurantId;
  final Menu menu;
  final VoidCallback onTap;
  final bool isSuspended;
  final bool highlightUnavailable;
  final VoidCallback? onAvailabilityChange;

  const ManagerMenuCard({
    super.key,
    required this.restaurantId,
    required this.menu,
    required this.onTap,
    this.isSuspended = false,
    this.highlightUnavailable = false,
    this.onAvailabilityChange,
  });

  @override
  State<ManagerMenuCard> createState() => _ManagerMenuCardState();
}

class _ManagerMenuCardState extends State<ManagerMenuCard> {
  bool _isLoading = false;

  Future<void> _toggleAvailability() async {
    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: widget.menu.available
            ? 'Rendre ce menu indisponible ?'
            : 'Rendre ce menu disponible ?',
        content: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppDialog.defaultContentStyle,
            children: [
              TextSpan(
                text: widget.menu.name,
                style: AppDialog.defaultContentStyle.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: widget.menu.available
                    ? ' ne sera plus disponible pour les clients. Les produits resteront disponibles selon leur statut.'
                    : ' sera de nouveau disponible pour les clients.',
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
          .read<ManagerCatalogMenusViewModel>()
          .toggleAvailability(widget.restaurantId, widget.menu.id);
      if (!mounted) return;

      final availabilityCallback = widget.onAvailabilityChange;

      if (success) {
        availabilityCallback?.call();
        if (availabilityCallback == null) {
          AppSnackbar.success(context, 'Menu mis à jour avec succès.');
        }
      } else {
        AppSnackbar.error(context, 'Erreur lors de la mise à jour du menu.');
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
    final menu = widget.menu;
    final hasStructure = menu.groupCount > 0 || menu.itemCount > 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppNetworkImage(
                    imageUrl: menu.imageUrl,
                    width: 76,
                    height: 76,
                    borderRadius: 18,
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
                                menu.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey.shade500,
                            ),
                          ],
                        ),
                        if (menu.description.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            menu.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                        const SizedBox(height: 5),
                        Text(
                          'Prix de base ${formatPrice(menu.price)}',
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
                          icon: Icons.account_tree_outlined,
                          label: hasStructure
                              ? '${menu.groupCount} groupes'
                              : 'Structure à vérifier',
                          color: hasStructure ? Colors.black54 : Colors.orange,
                        ),
                        AppInfoPill(
                          icon: Icons.format_list_bulleted_rounded,
                          label: '${menu.itemCount} items',
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  AppSwitch(
                    value: menu.available,
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
        ),
      ),
    );
  }
}
