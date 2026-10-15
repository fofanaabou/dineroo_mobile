import 'package:dineroo_mobile/shared/common/helpers/price_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_add_button.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_network_image.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_unavailable_overlay.dart';
import 'package:dineroo_mobile/shared/models/domain/menu.dart';
import 'package:dineroo_mobile/customer/models/domain/restaurant_detail.dart';
import 'package:dineroo_mobile/customer/models/extensions/restaurant_detail_extensions.dart';
import 'package:dineroo_mobile/customer/views/restaurant/menu/menu_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/common/helpers/navigation_helper.dart';

class RestaurantDetailMenu extends StatelessWidget {
  static const double _cardWidth = 250;
  static const double _imageHeight = 110;
  static const double _titleHeight = 40;
  static const double _descriptionHeight = 32;
  static const double _contentHorizontalPadding = 12;
  static const double _contentTopPadding = 12;
  static const double _contentBottomPadding = 10;

  final Menu menu;
  final RestaurantDetail restaurant;

  const RestaurantDetailMenu({
    super.key,
    required this.menu,
    required this.restaurant,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = menu.available;

    return GestureDetector(
      onTap: isAvailable
          ? () {
              navigateTo(
                context,
                MenuDetailView(
                  restaurant: restaurant.toRestaurant(),
                  menuId: menu.id,
                ),
              );
            }
          : null,
      child: Opacity(
        opacity: isAvailable ? 1.0 : 0.5,
        child: SizedBox(
          width: _cardWidth,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFDFDFD),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEDEDED)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    AppNetworkImage(
                      imageUrl: menu.imageUrl,
                      width: double.infinity,
                      height: _imageHeight,
                      borderRadius: 0,
                    ),
                    if (!isAvailable) const AppUnavailableOverlay(),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Menu',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    _contentHorizontalPadding,
                    _contentTopPadding,
                    _contentHorizontalPadding,
                    _contentBottomPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: _titleHeight,
                        child: Text(
                          menu.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        height: _descriptionHeight,
                        child: Text(
                          menu.description.isNotEmpty
                              ? menu.description
                              : 'Menu à composer',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Dès ${formatPrice(menu.price)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF5F5448),
                              ),
                            ),
                          ),
                          AppAddButton(
                            onTap: isAvailable
                                ? () {
                                    navigateTo(
                                      context,
                                      MenuDetailView(
                                        restaurant: restaurant.toRestaurant(),
                                        menuId: menu.id,
                                      ),
                                    );
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
