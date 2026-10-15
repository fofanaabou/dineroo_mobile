import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dineroo_mobile/manager/view_models/catalog/manager_catalog_menu_detail_view_model.dart';
import 'package:dineroo_mobile/manager/services/manager_menu_detail_service.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_error_retry.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_switch.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_network_image.dart';
import 'package:dineroo_mobile/shared/common/helpers/price_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_snackbar.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_dialog.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_info_pill.dart';
import 'package:dineroo_mobile/manager/models/manager_menu_detail.dart';
import 'package:dineroo_mobile/manager/views/manager_suspension_notice.dart';
import 'package:dineroo_mobile/shared/exceptions/restaurant_suspended_exception.dart';

class ManagerCatalogMenuDetailView extends StatefulWidget {
  final String restaurantId;
  final String menuId;
  final String menuName;
  final bool isSuspended;

  const ManagerCatalogMenuDetailView({
    super.key,
    required this.restaurantId,
    required this.menuId,
    required this.menuName,
    this.isSuspended = false,
  });

  @override
  State<ManagerCatalogMenuDetailView> createState() =>
      _ManagerCatalogMenuDetailViewState();
}

class _ManagerCatalogMenuDetailViewState
    extends State<ManagerCatalogMenuDetailView> {
  late ManagerCatalogMenuDetailViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = ManagerCatalogMenuDetailViewModel(
      ManagerMenuDetailService(),
      widget.restaurantId,
    );
    _vm.fetchMenuDetail(widget.menuId);
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _handleItemToggle(String groupId, String itemId) async {
    ManagerMenuItem? target;
    for (final group in _vm.menuDetail?.groups ?? <ManagerChoiceGroup>[]) {
      if (group.id != groupId) continue;
      for (final item in group.items) {
        if (item.id == itemId) {
          target = item;
          break;
        }
      }
    }

    if (target == null) return;

    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: target!.available
            ? 'Rendre cet item indisponible ?'
            : 'Rendre cet item disponible ?',
        content: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppDialog.defaultContentStyle,
            children: [
              TextSpan(
                text: target.productName,
                style: AppDialog.defaultContentStyle.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: target.available
                    ? ' ne pourra plus être sélectionné dans ce menu. Si le groupe obligatoire n’a plus aucun produit disponible, le menu ne sera plus commandable.'
                    : ' pourra à nouveau être sélectionné dans ce menu.',
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

    try {
      final success = await _vm.toggleItemAvailability(groupId, itemId);
      if (!mounted) return;
      if (success) {
        AppSnackbar.success(context, 'Disponibilité mise à jour');
      } else {
        AppSnackbar.error(context, 'Erreur lors de la mise à jour');
      }
    } on RestaurantSuspendedException {
      if (!mounted) return;
      await ManagerSuspensionNotice.showServerRefusalAndReloadRestaurant(
        context,
        restaurantId: widget.restaurantId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.menuName)),
        body: Consumer<ManagerCatalogMenuDetailViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const Center(child: AppLoader());
            }
            if (vm.hasError) {
              return AppErrorRetry(
                message: 'Impossible de charger le menu.',
                onPressed: () => vm.fetchMenuDetail(widget.menuId),
              );
            }
            final menu = vm.menuDetail;
            if (menu == null) {
              return const Center(child: Text('Menu introuvable'));
            }
            return _buildContent(context, menu);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ManagerMenuDetail menu) {
    final totalItems = menu.groups.fold<int>(
      0,
      (sum, group) => sum + group.items.length,
    );
    final unavailableItems = menu.groups.fold<int>(
      0,
      (sum, group) => sum + group.items.where((item) => !item.available).length,
    );

    return RefreshIndicator(
      onRefresh: () => _vm.fetchMenuDetail(widget.menuId),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _buildMenuHeader(menu, totalItems, unavailableItems),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Composition du menu',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 8),
          if (menu.groups.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Aucun groupe de choix',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...menu.groups.map((g) => _buildGroupCard(context, g)),
        ],
      ),
    );
  }

  Widget _buildMenuHeader(
    ManagerMenuDetail menu,
    int totalItems,
    int unavailableItems,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            SizedBox(
              height: 150,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(
                    imageUrl: menu.imageUrl,
                    width: double.infinity,
                    height: 150,
                    borderRadius: 0,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.72),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppInfoPill(
                          label: menu.available
                              ? 'Menu disponible'
                              : 'Menu indisponible',
                          color: menu.available
                              ? Colors.greenAccent
                              : Colors.orangeAccent,
                          backgroundColor: Colors.white.withValues(alpha: 0.14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          menu.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Prix de base ${formatPrice(menu.basePrice)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (menu.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      menu.description,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AppInfoPill(
                        icon: Icons.account_tree_outlined,
                        label: '${menu.groups.length} groupes',
                        color: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
                      ),
                      AppInfoPill(
                        icon: Icons.format_list_bulleted_rounded,
                        label: '$totalItems items',
                        color: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
                      ),
                      AppInfoPill(
                        icon: unavailableItems == 0
                            ? Icons.check_circle_outline
                            : Icons.warning_amber_rounded,
                        label: '$unavailableItems indispo.',
                        color: unavailableItems == 0
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
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

  Widget _buildGroupCard(BuildContext context, ManagerChoiceGroup group) {
    final availableCount = group.items.where((item) => item.available).length;
    final isBlocking = group.required && availableCount == 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isBlocking ? const Color(0xFFFFC4B6) : const Color(0xFFECECEC),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Le client choisit ${group.minSelections == group.maxSelections ? group.minSelections.toString() : 'de ${group.minSelections} à ${group.maxSelections}'} option${group.maxSelections > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (group.required)
                  const _ChoiceBadge(
                    label: 'Obligatoire',
                    color: Colors.deepOrange,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _ChoiceBadge(
                  label: '$availableCount/${group.items.length} disponibles',
                  color: isBlocking ? Colors.deepOrange : Colors.green,
                ),
                if (isBlocking)
                  const _ChoiceBadge(
                    label: 'Menu bloqué',
                    color: Colors.deepOrange,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (group.items.isEmpty)
              const Text('Aucun item', style: TextStyle(color: Colors.grey))
            else
              ...group.items.map(
                (item) => _buildItemRow(context, group.id, item),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(
    BuildContext context,
    String groupId,
    ManagerMenuItem item,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: item.available
            ? const Color(0xFFF8F8F8)
            : const Color(0xFFFFF6F3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          AppNetworkImage(
            imageUrl: item.productImageUrl,
            width: 46,
            height: 46,
            borderRadius: 12,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (item.additionalPrice > 0) ...[
                  const SizedBox(height: 4),
                  _ChoiceBadge(
                    label: '+${formatPrice(item.additionalPrice)}',
                    color: Colors.deepOrange,
                  ),
                ],
              ],
            ),
          ),
          AppSwitch(
            value: item.available,
            isDisabled: widget.isSuspended,
            onDisabledTap: () => ManagerSuspensionNotice.showLockedAction(context),
            onChanged: (_) => _handleItemToggle(groupId, item.id),
          ),
        ],
      ),
    );
  }
}

class _ChoiceBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _ChoiceBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
