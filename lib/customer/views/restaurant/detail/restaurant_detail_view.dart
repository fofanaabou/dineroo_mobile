import 'package:dineroo_mobile/shared/exceptions/restaurant_unavailable_exception.dart';
import 'package:dineroo_mobile/customer/models/extensions/restaurant_detail_extensions.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_collapsing_scaffold.dart';
import 'package:dineroo_mobile/shared/views/base_main_wrapper.dart';
import 'package:provider/provider.dart';
import 'package:dineroo_mobile/customer/view_models/restaurant/restaurant_view_model.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_back_button.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_error_retry.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_quick_access_navigation.dart';
import 'package:dineroo_mobile/customer/views/restaurant/detail/restaurant_detail_info.dart';
import 'package:dineroo_mobile/customer/views/restaurant/detail/restaurant_detail_menu.dart';
import 'package:dineroo_mobile/customer/views/restaurant/product_list.dart';
import 'package:dineroo_mobile/customer/view_models/cart/cart_view_model.dart';
import 'package:dineroo_mobile/customer/views/cart/grouped_cart_detail_view.dart';
import 'package:dineroo_mobile/shared/common/helpers/navigation_helper.dart';
import 'package:dineroo_mobile/shared/common/helpers/price_helper.dart';
import 'package:dineroo_mobile/shared/common/helpers/product_category_icon_helper.dart';
import 'package:dineroo_mobile/shared/common/utils/text_utils.dart';
import 'package:flutter/material.dart';

class RestaurantDetailView extends StatefulWidget {
  final String restaurantId;

  const RestaurantDetailView({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailView> createState() => _RestaurantDetailViewState();
}

class _RestaurantDetailViewState extends State<RestaurantDetailView> {
  static const double _menuCarouselHeight = 255;
  static const double _stickyAccessHeaderHeight = 56;
  static const double _sectionScrollGap = 2;

  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _productCategoryKeys = {};
  final ValueNotifier<String?> _selectedAccessLabel = ValueNotifier(null);
  bool _isProgrammaticAccessScroll = false;

  @override
  void initState() {
    super.initState();

    final vm = context.read<RestaurantViewModel>();
    vm.fetch(widget.restaurantId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _selectedAccessLabel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RestaurantViewModel>(
      builder: (context, viewModel, _) {
        Widget content;

        if (viewModel.isLoading) {
          content = const Scaffold(body: Center(child: AppLoader()));
        } else if (viewModel.error != null) {
          content = Stack(
            children: [
              AppErrorRetry(
                message: viewModel.isUnavailable
                    ? RestaurantUnavailableException.message
                    : AppErrorRetry.defaultMessage,
                icon: viewModel.isUnavailable
                    ? const Icon(
                        Icons.storefront_outlined,
                        size: 48,
                        color: Colors.grey,
                      )
                    : null,
                onPressed: () {
                  viewModel.fetch(widget.restaurantId);
                },
              ),
              const Positioned(top: 50, left: 16, child: AppBackButton()),
            ],
          );
        } else {
          final restaurant = viewModel.restaurant!;
          final standaloneProducts = restaurant.products
              .where((product) => product.canBeSoldAlone)
              .toList();
          final productCategories = _productCategories(standaloneProducts);
          for (final category in productCategories) {
            _productCategoryKeys.putIfAbsent(category, () => GlobalKey());
          }

          content = AppCollapsingScaffold(
            title: restaurant.name,
            imageUrl: restaurant.imageUrl,
            expandedHeaderHeight: 160,
            bottomNavigationBar: _RestaurantCartBar(
              restaurantId: restaurant.id,
            ),
            scrollController: _scrollController,
            onScroll: (_) => _syncSelectedAccessItem(productCategories),
            onRefresh: () => viewModel.fetch(widget.restaurantId),
            slivers: [
              SliverToBoxAdapter(
                child: RestaurantDetailInfo(restaurant: restaurant),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: _OrderingHint(
                    hasMenus: restaurant.menus.isNotEmpty,
                    hasProducts: standaloneProducts.isNotEmpty,
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: AppQuickAccessNavigationDelegate(
                  selectedLabelListenable: _selectedAccessLabel,
                  defaultSelectedLabel: '',
                  items: [
                    ...productCategories.map(
                      (category) => AppQuickAccessNavigationItem(
                        label: capitalize(category),
                        icon: iconForProductCategory(category),
                        imageUrl: _categoryImageUrl(
                          standaloneProducts,
                          category,
                        ),
                        onTap: () => _selectAndScroll(
                          capitalize(category),
                          _productCategoryKeys[category]!,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (restaurant.menus.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                    child: _SectionHeader(
                      title: 'Menus',
                      subtitle: 'Prix de base + suppléments éventuels',
                      count: restaurant.menus.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: _menuCarouselHeight,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: restaurant.menus.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return RestaurantDetailMenu(
                          menu: restaurant.menus[index],
                          restaurant: restaurant,
                        );
                      },
                    ),
                  ),
                ),
              ],
              if (standaloneProducts.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    child: _SectionHeader(
                      title: 'Produits',
                      subtitle: 'À ajouter directement au panier',
                      count: standaloneProducts.length,
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: ProductList(
                  products: standaloneProducts,
                  restaurant: restaurant.toRestaurant(),
                  sectionKeys: _productCategoryKeys,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        }

        return BaseMainWrapper(
          role: UserRole.customer,
          selectedIndex: 0,
          child: content,
        );
      },
    );
  }

  List<String> _productCategories(List<dynamic> products) {
    final categories = <String>[];
    for (final product in products) {
      final category = product.category;
      if (category.isNotEmpty && !categories.contains(category)) {
        categories.add(category);
      }
    }
    return categories;
  }

  String? _categoryImageUrl(List<dynamic> products, String category) {
    for (final product in products) {
      if (product.category == category && product.imageUrl.trim().isNotEmpty) {
        return product.imageUrl;
      }
    }
    return null;
  }

  Future<void> _scrollToKey(GlobalKey key) async {
    final targetContext = key.currentContext;
    if (targetContext == null || !_scrollController.hasClients) return;

    final targetBox = targetContext.findRenderObject() as RenderBox?;
    final scrollBox = context.findRenderObject() as RenderBox?;
    if (targetBox == null || scrollBox == null) return;

    final targetY = targetBox.localToGlobal(Offset.zero).dy;
    final scrollY = scrollBox.localToGlobal(Offset.zero).dy;
    final currentOffset = _scrollController.offset;
    final pinnedHeaderOffset =
        MediaQuery.paddingOf(context).top +
        kToolbarHeight +
        _stickyAccessHeaderHeight +
        _sectionScrollGap;
    final targetOffset = currentOffset + targetY - scrollY - pinnedHeaderOffset;
    final boundedOffset = targetOffset.clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );

    await _scrollController.animateTo(
      boundedOffset,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _selectAndScroll(String label, GlobalKey key) async {
    _isProgrammaticAccessScroll = true;
    _selectedAccessLabel.value = label;
    await _scrollToKey(key);
    if (!mounted) return;
    _selectedAccessLabel.value = label;
    _isProgrammaticAccessScroll = false;
  }

  void _syncSelectedAccessItem(List<String> productCategories) {
    if (_isProgrammaticAccessScroll) return;

    final visibleSections = <_SectionAnchor>[];

    for (final category in productCategories) {
      final key = _productCategoryKeys[category];
      if (key?.currentContext != null) {
        visibleSections.add(_SectionAnchor(capitalize(category), key!));
      }
    }

    if (visibleSections.isEmpty) return;

    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 2) {
      final lastLabel = visibleSections.last.label;
      if (_selectedAccessLabel.value != lastLabel && mounted) {
        _selectedAccessLabel.value = lastLabel;
      }
      return;
    }

    final activationY = MediaQuery.sizeOf(context).height * 0.55;
    final stickyHeaderBottom =
        MediaQuery.paddingOf(context).top +
        kToolbarHeight +
        _stickyAccessHeaderHeight;
    _SectionAnchor? active;
    for (final section in visibleSections) {
      final box = section.key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final top = box.localToGlobal(Offset.zero).dy;
      final bottom = top + box.size.height;
      if (top <= activationY && bottom > stickyHeaderBottom) {
        active = section;
      }
    }

    final nextLabel = active?.label;
    if (_selectedAccessLabel.value != nextLabel && mounted) {
      _selectedAccessLabel.value = nextLabel;
    }
  }
}

class _SectionAnchor {
  final String label;
  final GlobalKey key;

  const _SectionAnchor(this.label, this.key);
}

class _RestaurantCartBar extends StatelessWidget {
  final String restaurantId;

  const _RestaurantCartBar({required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartViewModel>(
      builder: (context, cartVM, _) {
        final groups = cartVM.groupedCarts
            .where((group) => group.restaurantId == restaurantId)
            .toList();

        if (groups.isEmpty) return const SizedBox.shrink();

        final group = groups.first;
        final itemCount = group.items.length;

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: FilledButton(
              onPressed: () =>
                  navigateTo(context, GroupedCartDetailView(group: group)),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                minimumSize: const Size.fromHeight(58),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    constraints: const BoxConstraints(minWidth: 34),
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$itemCount',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Voir le panier',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    formatPrice(group.subtotal),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OrderingHint extends StatelessWidget {
  final bool hasMenus;
  final bool hasProducts;

  const _OrderingHint({required this.hasMenus, required this.hasProducts});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFE0CC)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Colors.deepOrange,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasMenus && hasProducts
                  ? 'Découvrez la sélection du restaurant'
                  : hasMenus
                  ? 'Choisis un menu et configure tes accompagnements.'
                  : 'Ajoute tes produits préférés directement au panier.',
              style: const TextStyle(fontWeight: FontWeight.w800, height: 1.25),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final int count;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}
