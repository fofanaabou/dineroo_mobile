import 'dart:convert';

import 'package:dineroo_mobile/customer/models/domain/product_choice_item.dart';
import 'package:dineroo_mobile/customer/views/restaurant/product_detail_view.dart';
import 'package:dineroo_mobile/customer/views/restaurant/widgets/restaurant_choice_item_tile.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_collapsing_scaffold.dart';
import 'package:dineroo_mobile/customer/models/domain/restaurant.dart';
import 'package:dineroo_mobile/customer/view_models/cart/cart_view_model.dart';
import 'package:dineroo_mobile/customer/views/restaurant/menu/menu_detail_bottom_bar.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_snackbar.dart';
import 'package:dineroo_mobile/customer/views/restaurant/menu/menu_price_quantity.dart';
import 'package:dineroo_mobile/shared/common/widgets/restaurant_open_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:dineroo_mobile/customer/models/domain/menu_detail.dart';
import 'package:dineroo_mobile/customer/models/domain/choice_group.dart';
import 'package:dineroo_mobile/customer/models/domain/selected_menu_item.dart';
import 'package:provider/provider.dart';
import 'package:dineroo_mobile/customer/models/extensions/menu_detail_extensions.dart';
import 'package:dineroo_mobile/shared/common/colors.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_add_button.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_required_badge.dart';

class MenuDetailBody extends StatefulWidget {
  final MenuDetail menuDetail;
  final Restaurant restaurant;
  final Future<void> Function()? onRefresh;

  const MenuDetailBody({
    super.key,
    required this.menuDetail,
    required this.restaurant,
    this.onRefresh,
  });

  @override
  State<MenuDetailBody> createState() => _MenuDetailBodyState();
}

class _MenuDetailBodyState extends State<MenuDetailBody> {
  int quantity = 1;
  final Map<String, Map<String, int>> _selectedItems = {};
  final Map<String, GlobalKey> _groupKeys = {};
  final Map<String, Map<String, List<ProductChoiceItem>>> _configuredProducts =
      {};
  String _selectionErrorText = '';
  String? _selectionErrorGroupId;

  void increment() => setState(() => quantity++);

  void decrement() => setState(() {
    if (quantity > 1) quantity--;
  });

  @override
  void initState() {
    super.initState();
    for (final group in widget.menuDetail.choiceGroups) {
      _selectedItems[group.id] = {};
      _groupKeys[group.id] = GlobalKey();
    }
  }

  void _scrollToGroup(String groupId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetContext = _groupKeys[groupId]?.currentContext;
      if (targetContext == null) return;

      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  String _minimumSelectionErrorText(ChoiceGroup group) {
    return 'Veuillez sélectionner au moins ${group.minSelections} option${group.minSelections > 1 ? 's' : ''}';
  }

  bool _validateSelections() {
    for (final group in widget.menuDetail.choiceGroups) {
      final selected = _selectedCount(group.id);
      if (group.required && selected < group.minSelections) {
        setState(() {
          _selectionErrorGroupId = group.id;
          _selectionErrorText = _minimumSelectionErrorText(group);
        });
        _scrollToGroup(group.id);
        return false;
      }
      if (selected > group.maxSelections) {
        setState(() {
          _selectionErrorGroupId = group.id;
          _selectionErrorText =
              'Vous ne pouvez sélectionner que ${group.maxSelections} option${group.maxSelections > 1 ? 's' : ''} maximum';
        });
        _scrollToGroup(group.id);
        return false;
      }
    }
    setState(() {
      _selectionErrorGroupId = null;
      _selectionErrorText = '';
    });
    return true;
  }

  double _calculateTotalPrice() {
    double supplements = 0;
    for (final group in widget.menuDetail.choiceGroups) {
      final selectedQuantities = _selectedItems[group.id] ?? {};
      for (final item in group.items) {
        final itemQuantity = selectedQuantities[item.id] ?? 0;
        if (itemQuantity > 0) {
          supplements += item.additionalPrice * itemQuantity;
          final choices = _configuredProducts[group.id]?[item.id];
          if (choices != null) {
            for (final c in choices) {
              supplements += c.additionalPrice * c.quantity;
            }
          }
        }
      }
    }
    return (widget.menuDetail.price + supplements) * quantity;
  }

  List<SelectedMenuItem> _buildSelectedMenuItems() {
    final List<SelectedMenuItem> items = [];
    for (final group in widget.menuDetail.choiceGroups) {
      final selectedQuantities = _selectedItems[group.id] ?? {};
      for (final choiceItem in group.items) {
        final itemQuantity = selectedQuantities[choiceItem.id] ?? 0;
        for (var i = 0; i < itemQuantity; i++) {
          final productChoices = _configuredProducts[group.id]?[choiceItem.id];
          final choicesPrice =
              productChoices?.fold<double>(
                0.0,
                (sum, c) => sum + c.additionalPrice * c.quantity,
              ) ??
              0.0;
          items.add(
            SelectedMenuItem(
              groupId: group.id,
              groupName: group.name,
              menuItemId: choiceItem.id,
              productId: choiceItem.productId,
              productName: choiceItem.productName,
              additionalPrice: choiceItem.additionalPrice + choicesPrice,
              productChoicesJson: productChoices != null
                  ? jsonEncode(ProductChoiceItem.listToJson(productChoices))
                  : null,
            ),
          );
        }
      }
    }
    return items;
  }

  void _incrementSelection(String groupId, String itemId) {
    final group = widget.menuDetail.choiceGroups.firstWhere(
      (g) => g.id == groupId,
    );
    setState(() {
      final selected = _selectedItems[groupId]!;
      final totalSelected = _selectedCount(groupId);

      if (totalSelected >= group.maxSelections) {
        return;
      }

      selected[itemId] = (selected[itemId] ?? 0) + 1;

      if (_selectionErrorGroupId == group.id) {
        if (_selectedCount(groupId) >= group.minSelections) {
          _selectionErrorGroupId = null;
          _selectionErrorText = '';
        } else {
          _selectionErrorText = _minimumSelectionErrorText(group);
        }
      }
    });
  }

  void _decrementSelection(String groupId, String itemId) {
    final group = widget.menuDetail.choiceGroups.firstWhere(
      (g) => g.id == groupId,
    );
    setState(() {
      final selected = _selectedItems[groupId]!;
      final itemQuantity = selected[itemId] ?? 0;
      if (itemQuantity == 0) return;

      if (itemQuantity <= 1) {
        selected.remove(itemId);
        _configuredProducts[groupId]?.remove(itemId);
      } else {
        selected[itemId] = itemQuantity - 1;
      }

      if (_selectionErrorGroupId == group.id) {
        if (_selectedCount(groupId) >= group.minSelections) {
          _selectionErrorGroupId = null;
          _selectionErrorText = '';
        } else {
          _selectionErrorText = _minimumSelectionErrorText(group);
        }
      }
    });
  }

  int _selectedCount(String groupId) {
    return _selectedItems[groupId]?.values.fold<int>(
          0,
          (sum, value) => sum + value,
        ) ??
        0;
  }

  int _itemQuantity(String groupId, String itemId) {
    return _selectedItems[groupId]?[itemId] ?? 0;
  }

  bool _hasProductConfig(String groupId, String itemId) {
    return _configuredProducts[groupId]?[itemId] != null;
  }

  Future<void> _openConfigSheet(String groupId, ChoiceItem item) async {
    final choices = await showModalBottomSheet<List<ProductChoiceItem>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductDetailView(
        restaurantId: widget.restaurant.id,
        productId: item.productId,
        productName: item.productName,
        productImageUrl: item.productImageUrl,
      ),
    );
    if (choices == null) return;
    _incrementSelection(groupId, item.id);
    setState(() {
      if (choices.isNotEmpty) {
        _configuredProducts[groupId] ??= {};
        _configuredProducts[groupId]![item.id] = choices;
      }
    });
  }

  void addToCart() {
    if (widget.menuDetail.choiceGroups.isEmpty) {
      AppSnackbar.error(context, 'Ce menu n’est pas encore configurable');
      return;
    }

    if (!_validateSelections()) {
      return;
    }
    if (!mounted) return;

    final product = widget.menuDetail.toProduct(
      restaurantId: widget.restaurant.id,
      restaurantName: widget.restaurant.name,
    );
    final cartVM = Provider.of<CartViewModel>(context, listen: false);

    final selectedMenuItems = _buildSelectedMenuItems();
    cartVM.addConfiguredMenu(
      menuProduct: product,
      selectedItems: selectedMenuItems,
      menuBasePrice: widget.menuDetail.price,
      restaurantId: widget.restaurant.id,
      restaurantName: widget.restaurant.name,
      quantity: quantity,
    );

    AppSnackbar.success(
      context,
      'Ajouté au panier avec succès',
      bottomMargin: 100,
      duration: const Duration(seconds: 1),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppCollapsingScaffold(
      title: widget.menuDetail.name,
      imageUrl: widget.menuDetail.imageUrl,
      onRefresh: widget.onRefresh,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RestaurantOpenStatusBadge(
                  openingHours: widget.restaurant.openingHours,
                ),
                const SizedBox(height: 10),
                Text(
                  widget.menuDetail.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.menuDetail.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF999999),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                MenuPriceQuantity(unitPrice: widget.menuDetail.price),
              ],
            ),
          ),
        ),
        if (widget.menuDetail.choiceGroups.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildChoiceGroups(),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
      bottomNavigationBar: MenuDetailBottomBar(
        totalPrice: _calculateTotalPrice(),
        quantity: quantity,
        onIncrement: increment,
        onDecrement: decrement,
        onPressed: addToCart,
      ),
    );
  }

  Widget _buildChoiceGroups() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.menuDetail.choiceGroups
          .map((group) => _buildGroupSection(group))
          .toList(),
    );
  }

  Widget _buildGroupSection(ChoiceGroup group) {
    final selectedCount = _selectedCount(group.id);
    final isSatisfied = selectedCount >= group.minSelections;
    final hasSelectionError = _selectionErrorGroupId == group.id;

    return KeyedSubtree(
      key: _groupKeys[group.id],
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
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedCount > 0
                          ? '$selectedCount/${group.maxSelections} sélectionné${selectedCount > 1 ? 's' : ''}'
                          : 'Choisissez ${group.minSelections == group.maxSelections ? group.minSelections.toString() : 'de ${group.minSelections} à ${group.maxSelections}'} option${group.maxSelections > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSatisfied ? Colors.green : Colors.grey,
                        fontWeight: isSatisfied
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (group.required) AppRequiredBadge(isSatisfied: isSatisfied),
            ],
          ),
          const SizedBox(height: 12),
          if (hasSelectionError)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                _selectionErrorText,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ...group.items.indexed.map(
            (entry) => _buildChoiceItem(group, entry.$1, entry.$2),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildChoiceItem(ChoiceGroup group, int index, ChoiceItem item) {
    final itemQuantity = _itemQuantity(group.id, item.id);
    final selected = itemQuantity > 0;
    final isConfigurable = item.productConfigurable;
    final hasConfig = isConfigurable && _hasProductConfig(group.id, item.id);

    return RestaurantChoiceItemTile(
      item: item,
      index: index,
      showUnavailableLabel: true,
      metadata: [
        if (isConfigurable && selected && hasConfig)
          const Text(
            'Configuré',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
      ],
      trailing: _buildChoiceItemQuantityControl(group, item, itemQuantity),
    );
  }

  Widget _buildChoiceItemQuantityControl(
    ChoiceGroup group,
    ChoiceItem item,
    int itemQuantity,
  ) {
    final isConfigurable = item.productConfigurable;
    final canAdd =
        item.available && _selectedCount(group.id) < group.maxSelections;
    final canIncrement =
        item.available &&
        !isConfigurable &&
        _selectedCount(group.id) < group.maxSelections;
    final canDecrement = item.available && itemQuantity > 0;

    if (itemQuantity == 0) {
      return AppAddButton(
        onTap: canAdd
            ? () {
                if (isConfigurable) {
                  _openConfigSheet(group.id, item);
                } else {
                  _incrementSelection(group.id, item.id);
                }
              }
            : null,
      );
    }

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuantityButton(
            icon: Icons.remove,
            onTap: canDecrement
                ? () => _decrementSelection(group.id, item.id)
                : null,
          ),
          SizedBox(
            width: 22,
            child: Text(
              '$itemQuantity',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          _QuantityButton(
            icon: Icons.add,
            onTap: canIncrement
                ? () => _incrementSelection(group.id, item.id)
                : null,
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 16,
          color: disabled ? Colors.grey.shade300 : AppColors.orange,
        ),
      ),
    );
  }
}
