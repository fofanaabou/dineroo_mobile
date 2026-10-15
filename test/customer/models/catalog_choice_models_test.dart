import 'dart:convert';

import 'package:dineroo_mobile/customer/models/domain/product_choice_item.dart';
import 'package:dineroo_mobile/customer/models/domain/selected_menu_item.dart';
import 'package:dineroo_mobile/customer/models/dto/choice_group_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductChoiceItem', () {
    test('round-trips choices and preserves quantities and supplements', () {
      const choice = ProductChoiceItem(
        groupId: 'sauce',
        groupName: 'Sauces',
        itemId: 'piment',
        itemName: 'Piment',
        additionalPrice: 250,
        quantity: 2,
      );

      final json = choice.toJson();
      final parsed = ProductChoiceItem.fromJson(json);

      expect(parsed.groupId, 'sauce');
      expect(parsed.groupName, 'Sauces');
      expect(parsed.itemId, 'piment');
      expect(parsed.itemName, 'Piment');
      expect(parsed.additionalPrice, 250);
      expect(parsed.quantity, 2);
    });

    test('uses safe defaults when optional fields are absent', () {
      final parsed = ProductChoiceItem.fromJson({
        'groupId': 'side',
        'itemId': 'riz',
      });

      expect(parsed.groupName, isEmpty);
      expect(parsed.itemName, isEmpty);
      expect(parsed.additionalPrice, 0);
      expect(parsed.quantity, 1);
    });
  });

  group('SelectedMenuItem', () {
    test('decodes nested product choices used by configured menu items', () {
      final selected = SelectedMenuItem(
        groupId: 'main',
        groupName: 'Plat',
        menuItemId: 'chicken-item',
        productId: 'chicken',
        productName: 'Poulet',
        productChoicesJson: jsonEncode([
          {
            'groupId': 'sauce',
            'groupName': 'Sauces',
            'itemId': 'piment',
            'itemName': 'Piment',
            'additionalPrice': 250,
            'quantity': 2,
          },
        ]),
      );

      final choices = selected.productChoices;

      expect(choices, hasLength(1));
      expect(choices!.single.itemName, 'Piment');
      expect(choices.single.quantity, 2);
    });

    test('ignores empty or malformed nested choices instead of crashing', () {
      expect(
        SelectedMenuItem(
          groupId: 'g',
          groupName: 'Groupe',
          menuItemId: 'i',
          productId: 'p',
          productName: 'Produit',
        ).productChoices,
        isNull,
      );
      expect(
        SelectedMenuItem(
          groupId: 'g',
          groupName: 'Groupe',
          menuItemId: 'i',
          productId: 'p',
          productName: 'Produit',
          productChoicesJson: '{not-json',
        ).productChoices,
        isNull,
      );
    });
  });

  group('ChoiceGroupDto', () {
    test('parses camelCase and snake_case restaurant catalogue payloads', () {
      final dto = ChoiceGroupDto.fromJson({
        'id': 12,
        'name': 'Accompagnement',
        'required': true,
        'minSelections': 1,
        'maxSelections': 2,
        'displayOrder': 3,
        'items': [
          {
            'id': 'item-1',
            'productId': 'product-1',
            'productName': 'Riz',
            'product_image_url': 'https://img/riz.jpg',
            'product_description': 'Riz blanc',
            'product_configurable': true,
            'additional_price': 500,
            'available': false,
            'displayOrder': 4,
          },
        ],
      });

      final domain = dto.toDomain();

      expect(domain.id, '12');
      expect(domain.required, isTrue);
      expect(domain.minSelections, 1);
      expect(domain.maxSelections, 2);
      expect(domain.displayOrder, 3);
      expect(domain.items.single.productImageUrl, 'https://img/riz.jpg');
      expect(domain.items.single.productDescription, 'Riz blanc');
      expect(domain.items.single.productConfigurable, isTrue);
      expect(domain.items.single.additionalPrice, 500);
      expect(domain.items.single.available, isFalse);
      expect(domain.items.single.displayOrder, 4);
    });

    test('coerces numeric doubles into int fields', () {
      final dto = ChoiceGroupDto.fromJson({
        'id': 'g',
        'name': 'Groupe',
        'minSelections': 1.0,
        'maxSelections': 3.0,
        'displayOrder': 2.0,
        'items': [
          {
            'id': 'item-1',
            'productId': 'product-1',
            'productName': 'Riz',
            'displayOrder': 4.0,
          },
        ],
      });

      expect(dto.minSelections, 1);
      expect(dto.maxSelections, 3);
      expect(dto.displayOrder, 2);
      expect(dto.items.single.displayOrder, 4);
    });

    test('defaults optional group and item values when backend omits them', () {
      final dto = ChoiceGroupDto.fromJson({'items': <Object>[]});

      expect(dto.id, isEmpty);
      expect(dto.name, isEmpty);
      expect(dto.required, isFalse);
      expect(dto.minSelections, 1);
      expect(dto.maxSelections, 1);
      expect(dto.items, isEmpty);
    });
  });
}
