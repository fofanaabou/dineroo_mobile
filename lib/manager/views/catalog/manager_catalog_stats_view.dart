import 'package:dineroo_mobile/manager/view_models/catalog/manager_catalog_menus_view_model.dart';
import 'package:dineroo_mobile/manager/view_models/catalog/manager_catalog_products_view_model.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_info_pill.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ManagerCatalogStatsEntry extends StatelessWidget {
  const ManagerCatalogStatsEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFE0D2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          final menusVm = context.read<ManagerCatalogMenusViewModel>();
          final productsVm = context.read<ManagerCatalogProductsViewModel>();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MultiProvider(
                providers: [
                  ChangeNotifierProvider.value(value: menusVm),
                  ChangeNotifierProvider.value(value: productsVm),
                ],
                child: const ManagerCatalogStatsView(),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Colors.deepOrange,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statistiques du catalogue',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Color(0xFF181C2E),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Menus, produits, groupes et items.',
                      style: TextStyle(color: Colors.black54, height: 1.25),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.deepOrange),
            ],
          ),
        ),
      ),
    );
  }
}

class ManagerCatalogStatsView extends StatelessWidget {
  const ManagerCatalogStatsView({super.key});

  @override
  Widget build(BuildContext context) {
    final menusVm = context.watch<ManagerCatalogMenusViewModel>();
    final productsVm = context.watch<ManagerCatalogProductsViewModel>();
    final totalProductCount = productsVm.allProducts.length;
    final standaloneProductCount = productsVm.products.length;
    final menuCount = menusVm.menus.length;
    final groupCount = menusVm.menus.fold<int>(
      0,
      (sum, menu) => sum + menu.groupCount,
    );
    final itemCount = menusVm.menus.fold<int>(
      0,
      (sum, menu) => sum + menu.itemCount,
    );

    return AppScaffold(
      title: 'Statistiques',
      showBack: true,
      showCartIcon: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF4EC), Color(0xFFFFFBF7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0xFFFFE0D2)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.deepOrange,
                        size: 30,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Catalogue importé',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: Color(0xFF181C2E),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Vue d’ensemble des éléments disponibles dans votre catalogue.',
                    style: TextStyle(color: Colors.black54, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                _StatsCard(
                  label: 'Menus',
                  value: '$menuCount',
                  icon: Icons.menu_book_outlined,
                  color: Colors.deepOrange,
                ),
                _StatsCard(
                  label: 'Produits',
                  value: '$totalProductCount',
                  icon: Icons.inventory_2_outlined,
                  color: Colors.teal,
                ),
                _StatsCard(
                  label: 'Produits vendus à l’unité',
                  value: '$standaloneProductCount',
                  icon: Icons.shopping_bag_outlined,
                  color: Colors.green,
                  maxLines: 2,
                ),
                _StatsCard(
                  label: 'Groupes',
                  value: '$groupCount',
                  icon: Icons.account_tree_outlined,
                  color: Colors.blueGrey,
                ),
                _StatsCard(
                  label: 'Items',
                  value: '$itemCount',
                  icon: Icons.format_list_bulleted_rounded,
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int maxLines;

  const _StatsCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFECECEC)),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  color: Color(0xFF181C2E),
                ),
              ),
              const SizedBox(height: 8),
              AppInfoPill(
                icon: icon,
                label: label,
                color: color,
                backgroundColor: color.withValues(alpha: 0.08),
                maxLines: maxLines,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
