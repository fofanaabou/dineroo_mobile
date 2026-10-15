import 'package:dineroo_mobile/customer/models/domain/choice_group.dart';
import 'package:dineroo_mobile/customer/models/domain/product.dart';
import 'package:dineroo_mobile/customer/views/restaurant/widgets/restaurant_choice_item_tile.dart';
import 'package:dineroo_mobile/customer/view_models/restaurant/product_detail_view_model.dart';
import 'package:dineroo_mobile/shared/common/helpers/price_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_error_retry.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_network_image.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_add_button.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_required_badge.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProductDetailView extends StatefulWidget {
  final String restaurantId;
  final String productId;
  final String productName;
  final String productImageUrl;

  const ProductDetailView({
    super.key,
    required this.restaurantId,
    required this.productId,
    required this.productName,
    this.productImageUrl = '',
  });

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  late final ProductDetailViewModel _viewModel;
  final Map<String, GlobalKey> _groupKeys = {};

  @override
  void initState() {
    super.initState();
    _viewModel = ProductDetailViewModel()
      ..fetchProduct(widget.restaurantId, widget.productId);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _scrollToGroup(String groupId) {
    final key = _groupKeys[groupId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        alignment: 0.5,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  void _syncGroupKeys(Product product) {
    final groupIds = product.choiceGroups.map((group) => group.id).toSet();
    _groupKeys.removeWhere((groupId, _) => !groupIds.contains(groupId));
    for (final groupId in groupIds) {
      _groupKeys.putIfAbsent(groupId, () => GlobalKey());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProductDetailViewModel>.value(
      value: _viewModel,
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Consumer<ProductDetailViewModel>(
              builder: (context, viewModel, _) =>
                  _buildBody(scrollController, viewModel),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    ScrollController scrollController,
    ProductDetailViewModel viewModel,
  ) {
    if (viewModel.isLoading) {
      return const Center(child: AppLoader());
    }

    if (viewModel.error != null) {
      return AppErrorRetry(
        onPressed: () =>
            viewModel.fetchProduct(widget.restaurantId, widget.productId),
      );
    }

    final product = viewModel.product!;
    _syncGroupKeys(product);

    return Column(
      children: [
        _buildHeader(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildProductHeader(product),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            children: [
              ...product.choiceGroups.map(
                (group) => _buildGroupCard(group, viewModel),
              ),
            ],
          ),
        ),
        _buildBottomBar(viewModel),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Spacer(),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildProductHeader(Product product) {
    return Row(
      children: [
        if (widget.productImageUrl.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              clipBehavior: Clip.antiAlias,
              child: AppNetworkImage(
                imageUrl: widget.productImageUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (product.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  product.description,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroupCard(ChoiceGroup group, ProductDetailViewModel viewModel) {
    final selectedCount = viewModel.selectedCount(group.id);
    final isSatisfied = selectedCount >= group.minSelections;
    final hasSelectionError = viewModel.selectionErrorGroupId == group.id;

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
                      'Choisissez ${group.minSelections == group.maxSelections ? group.minSelections.toString() : 'de ${group.minSelections} à ${group.maxSelections}'} option${group.maxSelections > 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                viewModel.selectionErrorText,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ...group.items.indexed.map(
            (entry) => _buildChoiceItem(group, entry.$1, entry.$2, viewModel),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildChoiceItem(
    ChoiceGroup group,
    int index,
    ChoiceItem item,
    ProductDetailViewModel viewModel,
  ) {
    final itemQuantity = viewModel.itemQuantity(group.id, item.id);

    return RestaurantChoiceItemTile(
      item: item,
      index: index,
      dimUnavailable: true,
      trailing: _buildQuantityControl(group, item, itemQuantity, viewModel),
    );
  }

  Widget _buildQuantityControl(
    ChoiceGroup group,
    ChoiceItem item,
    int itemQuantity,
    ProductDetailViewModel viewModel,
  ) {
    final canDecrement = item.available && itemQuantity > 0;
    final canIncrement =
        item.available &&
        viewModel.selectedCount(group.id) < group.maxSelections;

    if (itemQuantity == 0) {
      return AppAddButton(
        onTap: canIncrement
            ? () => viewModel.incrementSelection(group.id, item.id)
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
          _ProductQuantityButton(
            icon: Icons.remove,
            onTap: canDecrement
                ? () => viewModel.decrementSelection(group.id, item.id)
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
          _ProductQuantityButton(
            icon: Icons.add,
            onTap: canIncrement
                ? () => viewModel.incrementSelection(group.id, item.id)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ProductDetailViewModel viewModel) {
    final total = viewModel.calculateTotalPrice();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              if (!viewModel.validateSelections()) {
                final groupId = viewModel.selectionErrorGroupId;
                if (groupId != null) _scrollToGroup(groupId);
                return;
              }
              Navigator.of(context).pop(viewModel.buildChoices());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'Confirmer — ${formatPrice(total)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductQuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ProductQuantityButton({required this.icon, required this.onTap});

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
          color: disabled ? Colors.grey.shade300 : Colors.deepOrange,
        ),
      ),
    );
  }
}
