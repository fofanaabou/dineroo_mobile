import 'package:dineroo_mobile/manager/views/catalog/manager_catalog_menu_detail_view.dart';
import 'package:dineroo_mobile/manager/views/catalog/manager_catalog_menus_tab.dart';
import 'package:dineroo_mobile/manager/views/catalog/manager_catalog_products_tab.dart';
import 'package:dineroo_mobile/manager/view_models/catalog/manager_catalog_menus_view_model.dart';
import 'package:dineroo_mobile/manager/view_models/catalog/manager_catalog_products_view_model.dart';
import 'package:dineroo_mobile/manager/view_models/restaurant/manager_restaurant_view_model.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_scaffold.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ManagerCatalogView extends StatefulWidget {
  final String restaurantId;
  const ManagerCatalogView({super.key, required this.restaurantId});

  @override
  State<ManagerCatalogView> createState() => _ManagerCatalogViewState();
}

class _ManagerCatalogViewState extends State<ManagerCatalogView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSuspended = context.watch<ManagerRestaurantViewModel>().isSuspended;

    return AppScaffold(
      title: 'Catalogue',
      showCartIcon: false,
      bottom: TabBar(
        controller: _tabController,
        tabs: [
          const Tab(text: 'Menus'),
          const Tab(text: 'Produits'),
          const Tab(text: 'Indispo.'),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ManagerCatalogMenusTab(
            restaurantId: widget.restaurantId,
            isSuspended: isSuspended,
          ),
          ManagerCatalogProductsTab(
            restaurantId: widget.restaurantId,
            isSuspended: isSuspended,
          ),
          _UnavailableCatalogueTab(
            restaurantId: widget.restaurantId,
            isSuspended: isSuspended,
          ),
        ],
      ),
    );
  }
}

class _UnavailableCatalogueTab extends StatelessWidget {
  final String restaurantId;
  final bool isSuspended;

  const _UnavailableCatalogueTab({
    required this.restaurantId,
    required this.isSuspended,
  });

  @override
  Widget build(BuildContext context) {
    final menusVm = context.watch<ManagerCatalogMenusViewModel>();
    final productsVm = context.watch<ManagerCatalogProductsViewModel>();
    final unavailableProducts = productsVm.products
        .where((product) => !product.available)
        .toList();
    final unavailableMenus = menusVm.menus
        .where((menu) => !menu.available)
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          menusVm.fetchMenus(restaurantId),
          productsVm.fetchProducts(restaurantId),
        ]);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (unavailableProducts.isEmpty && unavailableMenus.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 48, 24, 0),
              child: _EmptyOperationalState(
                icon: Icons.check_circle_outline,
                title: 'Tout est disponible',
                message:
                    'Aucun produit ou menu importé n’est marqué indisponible.',
              ),
            )
          else ...[
            if (unavailableProducts.isNotEmpty) ...[
              _SectionTitle(
                title: 'Produits indisponibles',
                count: unavailableProducts.length,
              ),
              ...unavailableProducts.map(
                (product) => ManagerProductCard(
                  restaurantId: restaurantId,
                  product: product,
                  isSuspended: isSuspended,
                  highlightUnavailable: true,
                  onAvailabilityChange: () => AppSnackbar.success(
                    context,
                    'Produit mis à jour avec succès.',
                  ),
                ),
              ),
            ],
            if (unavailableMenus.isNotEmpty) ...[
              _SectionTitle(
                title: 'Menus indisponibles',
                count: unavailableMenus.length,
              ),
              ...unavailableMenus.map(
                (menu) => ManagerMenuCard(
                  restaurantId: restaurantId,
                  menu: menu,
                  isSuspended: isSuspended,
                  highlightUnavailable: true,
                  onAvailabilityChange: () => AppSnackbar.success(
                    context,
                    'Menu mis à jour avec succès.',
                  ),
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
                    ).then((_) => menusVm.fetchMenus(restaurantId));
                  },
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;

  const _SectionTitle({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
          Text('$count', style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _EmptyOperationalState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyOperationalState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.green, size: 42),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
      ],
    );
  }
}
