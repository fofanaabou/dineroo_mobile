import 'package:dineroo_mobile/customer/views/cart/delivery_info_section.dart';
import 'package:dineroo_mobile/customer/views/cart/restaurant_open_status_banner.dart';
import 'package:dineroo_mobile/shared/common/helpers/navigation_helper.dart';
import 'package:dineroo_mobile/shared/common/helpers/price_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_empty_state.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dineroo_mobile/customer/models/domain/cart_group.dart';
import 'package:dineroo_mobile/customer/views/cart/cart_item_tile.dart';
import 'package:dineroo_mobile/customer/views/cart/cart_summary_row.dart';
import 'package:dineroo_mobile/customer/views/cart/cart_bottom_bar.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_scaffold.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_text_area.dart';
import 'package:dineroo_mobile/customer/view_models/cart/cart_view_model.dart';
import 'package:dineroo_mobile/shared/views/location/location_access_view.dart';
import 'package:dineroo_mobile/shared/view_models/location/location_view_model.dart';
import 'package:dineroo_mobile/shared/views/base_main_wrapper.dart';
import 'package:dineroo_mobile/shared/enums/main_view_tabs.dart';
import 'package:latlong2/latlong.dart';

class GroupedCartDetailView extends StatefulWidget {
  final CartGroup group;

  const GroupedCartDetailView({super.key, required this.group});

  @override
  State<GroupedCartDetailView> createState() => _GroupedCartDetailViewState();
}

class _GroupedCartDetailViewState extends State<GroupedCartDetailView> {
  LatLng? _lastSyncedPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cartVM = context.read<CartViewModel>();
      cartVM.clearUnavailableItemsForRestaurant(widget.group.restaurantId);
      cartVM.refreshCartImagesForRestaurant(widget.group.restaurantId);
      cartVM.estimateForRestaurant(widget.group.restaurantId);
    });
  }

  bool _isSamePosition(LatLng? a, LatLng? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.latitude == b.latitude && a.longitude == b.longitude;
  }

  void _syncCustomerPosition(LatLng? position) {
    if (_isSamePosition(_lastSyncedPosition, position)) return;
    _lastSyncedPosition = position;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CartViewModel>().updateCustomerPosition(position);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartVM = context.watch<CartViewModel>();
    final userPosition = context.select<LocationViewModel, LatLng?>(
      (locationVM) => locationVM.userPosition,
    );
    _syncCustomerPosition(userPosition);

    final currentGroups = cartVM.groupedCarts.where(
      (g) => g.restaurantId == widget.group.restaurantId,
    );
    final updatedGroup = currentGroups.isEmpty ? null : currentGroups.first;

    if (updatedGroup == null) {
      return BaseMainWrapper(
        role: UserRole.customer,
        selectedIndex: CustomerMainViewTab.cart.index,
        child: AppScaffold(
          title: widget.group.restaurantName.isNotEmpty
              ? widget.group.restaurantName
              : 'Détail commande',
          showBack: true,
          body: const Padding(
            padding: EdgeInsets.all(24),
            child: AppEmptyState(
              icon: Icons.shopping_cart_outlined,
              message: 'Votre panier est vide.',
            ),
          ),
        ),
      );
    }

    final isEstimating = cartVM.isEstimating(updatedGroup.restaurantId);
    final subtotal = cartVM.subtotalFor(updatedGroup);
    final deliveryFee = cartVM.deliveryFeeFor(updatedGroup);
    final serviceFee = cartVM.serviceFeeFor(updatedGroup);
    final total = cartVM.totalFor(updatedGroup);
    final hasEstimation = cartVM.hasEstimationFor(updatedGroup.restaurantId);
    final canEstimate = cartVM.canEstimateFor(updatedGroup);

    final content = AppScaffold(
      title: updatedGroup.restaurantName.isNotEmpty
          ? updatedGroup.restaurantName
          : 'Détail commande',
      showBack: true,
      body: Stack(
        children: [
          // Not a ListView: its estimated extent changes while scrolling these
          // mixed-height children, which makes the iOS bounce oscillate.
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RestaurantOpenStatusBanner(
                  restaurantId: updatedGroup.restaurantId,
                ),
                const DeliveryInfoSection(),
                if (!cartVM.hasDeliveryAddressForEstimation)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFE0B2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Renseignez l’adresse de livraison pour continuer.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                if (!cartVM.hasCustomerPosition)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFE0B2)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 16,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Activez votre position pour afficher l’estimation de livraison.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            replaceWith(context, const LocationAccessView());
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Activer',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                const Text(
                  'Mon panier',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...updatedGroup.items.map(
                  (item) => CartItemTile(item: item, cartVM: cartVM),
                ),
                const SizedBox(height: 16),

                AppTextArea(
                  controller: cartVM.commentController,
                  label: 'Ajouter un commentaire',
                  hintText: 'Par exemple : sans oignons',
                  maxLength: 300,
                ),
                const SizedBox(height: 24),

                if (hasEstimation || isEstimating || canEstimate) ...[
                  const Text(
                    'Résumé de la commande',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: Column(
                        children: [
                          if (hasEstimation) ...[
                            CartSummaryRow(
                              label: 'Sous-total',
                              amount: subtotal,
                            ),
                            const SizedBox(height: 8),
                            CartSummaryRow(
                              label: 'Frais de livraison',
                              amount: deliveryFee,
                            ),
                            const SizedBox(height: 8),
                            CartSummaryRow(
                              label: 'Frais de service',
                              amount: serviceFee,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(thickness: 1),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total à payer',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  formatPrice(total!),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lock, size: 16, color: Colors.grey),
                                SizedBox(width: 6),
                                Text(
                                  'Paiement 100% sécurisé',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ] else if (isEstimating) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AppLoader(size: 16, strokeWidth: 2),
                                  SizedBox(width: 10),
                                  Text(
                                    'Calcul des frais en cours...',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3F2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFFFDAD6),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 16,
                                    color: Colors.redAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Estimation indisponible pour le moment.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      cartVM.estimateForRestaurant(
                                        updatedGroup.restaurantId,
                                      );
                                    },
                                    child: const Text('Reessayer'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
          CartBottomBar(group: updatedGroup),
        ],
      ),
    );

    return BaseMainWrapper(
      role: UserRole.customer,
      selectedIndex: CustomerMainViewTab.cart.index,
      child: content,
    );
  }
}
