import 'package:dineroo_mobile/customer/models/domain/choice_group.dart';
import 'package:dineroo_mobile/customer/models/domain/product.dart';
import 'package:dineroo_mobile/customer/models/domain/product_choice_item.dart';
import 'package:dineroo_mobile/customer/models/dto/product_dto.dart';
import 'package:dineroo_mobile/customer/services/restaurant/product_service.dart';
import 'package:flutter/material.dart';

class ProductDetailViewModel extends ChangeNotifier {
  final ProductService _service;

  ProductDetailViewModel({ProductService? productService})
    : _service = productService ?? ProductService();

  Product? product;
  bool isLoading = true;
  String? error;
  String? selectionErrorGroupId;
  String selectionErrorText = '';

  final Map<String, Map<String, int>> _selectedItems = {};

  Future<void> fetchProduct(String restaurantId, String productId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final json = await _service.fetchProductDetail(restaurantId, productId);
      final fetchedProduct = ProductDto.fromJson(json).toDomain();
      product = fetchedProduct;
      _selectedItems.clear();
      for (final group in fetchedProduct.choiceGroups) {
        _selectedItems[group.id] = {};
      }
      selectionErrorGroupId = null;
      selectionErrorText = '';
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  int selectedCount(String groupId) {
    final items = _selectedItems[groupId];
    if (items == null) return 0;
    return items.values.fold(0, (sum, qty) => sum + qty);
  }

  int itemQuantity(String groupId, String itemId) {
    return _selectedItems[groupId]?[itemId] ?? 0;
  }

  void incrementSelection(String groupId, String itemId) {
    final group = product!.choiceGroups.firstWhere((g) => g.id == groupId);
    if (selectedCount(groupId) >= group.maxSelections) return;

    _selectedItems[groupId] ??= {};
    _selectedItems[groupId]![itemId] =
        (_selectedItems[groupId]![itemId] ?? 0) + 1;
    _clearSelectionErrorIfSatisfied(group);
    notifyListeners();
  }

  void decrementSelection(String groupId, String itemId) {
    final currentQty = itemQuantity(groupId, itemId);
    if (currentQty <= 0) return;

    if (currentQty <= 1) {
      _selectedItems[groupId]!.remove(itemId);
    } else {
      _selectedItems[groupId]![itemId] = currentQty - 1;
    }
    notifyListeners();
  }

  bool validateSelections() {
    final currentProduct = product;
    if (currentProduct == null) return false;

    for (final group in currentProduct.choiceGroups) {
      final selected = selectedCount(group.id);
      if (group.required && selected < group.minSelections) {
        selectionErrorGroupId = group.id;
        selectionErrorText = group.minSelections == group.maxSelections
            ? 'Veuillez sélectionner ${group.minSelections} option${group.minSelections > 1 ? 's' : ''}'
            : 'Veuillez sélectionner au moins ${group.minSelections} option${group.minSelections > 1 ? 's' : ''}';
        notifyListeners();
        return false;
      }
      if (selected > group.maxSelections) {
        selectionErrorGroupId = group.id;
        selectionErrorText =
            'Maximum ${group.maxSelections} option${group.maxSelections > 1 ? 's' : ''}';
        notifyListeners();
        return false;
      }
    }

    selectionErrorGroupId = null;
    selectionErrorText = '';
    notifyListeners();
    return true;
  }

  double calculateTotalPrice() {
    final currentProduct = product;
    if (currentProduct == null) return 0;

    double total = currentProduct.price;
    for (final group in currentProduct.choiceGroups) {
      for (final item in group.items) {
        final qty = itemQuantity(group.id, item.id);
        if (qty > 0) {
          total += item.additionalPrice * qty;
        }
      }
    }
    return total;
  }

  List<ProductChoiceItem> buildChoices() {
    final currentProduct = product;
    if (currentProduct == null) return [];

    final choices = <ProductChoiceItem>[];
    for (final group in currentProduct.choiceGroups) {
      for (final item in group.items) {
        final qty = itemQuantity(group.id, item.id);
        if (qty > 0) {
          choices.add(
            ProductChoiceItem(
              groupId: group.id,
              groupName: group.name,
              itemId: item.id,
              itemName: item.productName,
              additionalPrice: item.additionalPrice,
              quantity: qty,
            ),
          );
        }
      }
    }
    return choices;
  }

  void _clearSelectionErrorIfSatisfied(ChoiceGroup group) {
    if (selectionErrorGroupId != group.id) return;
    if (selectedCount(group.id) < group.minSelections) return;

    selectionErrorGroupId = null;
    selectionErrorText = '';
  }
}
