import 'package:dineroo_mobile/shared/common/helpers/product_category_icon_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('iconForProductCategory', () {
    test(
      'normalizes accents and maps catalogue categories to stable icons',
      () {
        expect(
          iconForProductCategory(' Formule midi '),
          Icons.menu_book_outlined,
        );
        expect(
          iconForProductCategory('Nouveauté'),
          Icons.auto_awesome_outlined,
        );
        expect(iconForProductCategory('Entrée'), Icons.tapas_outlined);
        expect(
          iconForProductCategory('Spécialité guinéenne'),
          Icons.restaurant_outlined,
        );
        expect(iconForProductCategory('Riz gras'), Icons.rice_bowl_outlined);
        expect(
          iconForProductCategory('Poulet grillé'),
          Icons.kebab_dining_outlined,
        );
        expect(
          iconForProductCategory('Poisson braisé'),
          Icons.set_meal_outlined,
        );
        expect(
          iconForProductCategory('Accompagnement frites'),
          Icons.ramen_dining_outlined,
        );
        expect(
          iconForProductCategory('Boisson bissap'),
          Icons.local_drink_outlined,
        );
      },
    );

    test('falls back to category icon for unknown categories', () {
      expect(iconForProductCategory('Divers'), Icons.category_outlined);
    });
  });
}
