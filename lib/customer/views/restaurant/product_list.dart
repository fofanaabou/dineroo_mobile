import 'package:dineroo_mobile/customer/models/domain/restaurant.dart';
import 'package:dineroo_mobile/customer/views/restaurant/product_card.dart';
import 'package:dineroo_mobile/shared/common/utils/text_utils.dart';
import 'package:flutter/material.dart';
import 'package:dineroo_mobile/customer/models/domain/product.dart';

class ProductList extends StatelessWidget {
  final List<Product> products;
  final Restaurant restaurant;
  final Map<String, GlobalKey>? sectionKeys;

  const ProductList({
    super.key,
    required this.products,
    required this.restaurant,
    this.sectionKeys,
  });

  @override
  Widget build(BuildContext context) {
    final standaloneProducts = products
        .where((product) => product.canBeSoldAlone)
        .toList();

    if (standaloneProducts.isEmpty) return const SizedBox.shrink();

    final grouped = _groupByType(standaloneProducts);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        return KeyedSubtree(
          key: sectionKeys?[entry.key],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  capitalize(entry.key),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Roboto',
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: entry.value.length,
                itemBuilder: (context, index) {
                  return ProductCard(
                    product: entry.value[index],
                    restaurant: restaurant,
                  );
                },
                separatorBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Colors.grey.shade200,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Map<String, List<Product>> _groupByType(List<Product> products) {
    final Map<String, List<Product>> map = {};
    for (final p in products) {
      map.putIfAbsent(p.category, () => []).add(p);
    }
    return map;
  }
}
