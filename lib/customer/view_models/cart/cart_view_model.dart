import 'package:dineroo_mobile/customer/models/domain/cart_group.dart';
import 'package:dineroo_mobile/customer/exceptions/order_estimation_exception.dart';
import 'package:dineroo_mobile/customer/models/domain/delivery_address.dart';
import 'package:dineroo_mobile/customer/models/domain/order_estimation.dart';
import 'package:dineroo_mobile/customer/models/domain/selected_menu_item.dart';
import 'package:dineroo_mobile/customer/services/order/order_service.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/common/utils/restaurant_item_image_urls.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:async';
import 'package:latlong2/latlong.dart';
import '../../models/domain/cart.dart';
import '../../models/domain/cart_item.dart';
import '../../models/domain/product.dart';
import '../../services/restaurant/restaurant_service.dart';

class CartViewModel extends ChangeNotifier {
  Box<CartItem>? _userCartBox;
  final _deliveryBox = Hive.box<DeliveryAddress>('deliveryAddressBox');
  final OrderService _orderService;
  final RestaurantService _restaurantService;
  final List<CartItem> _items = [];
  final TextEditingController commentController = TextEditingController();
  final Map<String, OrderEstimation> _estimationsByRestaurant = {};
  final Map<String, Map<String, dynamic>> _restaurantLocations = {};
  final Map<String, Set<String>> _unavailableItemNamesByRestaurant = {};
  final Set<String> _loadingEstimations = <String>{};
  final Set<String> _refreshingImageRestaurants = <String>{};
  final Map<String, Timer> _estimateDebounces = {};
  final Map<String, String> _lastEstimateSignatureByRestaurant = {};
  LatLng? _customerPosition;

  String? _restaurantId;
  String? _restaurantName;
  DeliveryAddress? _delivery;
  bool _isDeliveryConfirmedForCurrentOrder = false;
  String? _currentUserId;

  CartViewModel({
    OrderService? orderService,
    RestaurantService? restaurantService,
  }) : _orderService = orderService ?? OrderService(),
       _restaurantService = restaurantService ?? RestaurantService();

  List<CartItem> get items => _items;
  String? get restaurantId => _restaurantId;
  String? get restaurantName => _restaurantName;

  String? get deliveryLabel => _delivery?.displayLabel;
  String? get deliveryDisplayName => _delivery?.displayName;

  String? get deliveryPhoneNumber => _delivery?.phoneNumber;
  String? get deliveryAddress => _delivery?.address;
  String? get deliveryDistrict => _delivery?.district;
  String? get deliveryCommune => _delivery?.commune;
  String? get deliveryInstructions => _delivery?.instructions;
  String? get deliveryFirstName => _delivery?.firstName;
  String? get deliveryLastName => _delivery?.lastName;
  bool get isDeliveryConfirmedForCurrentOrder =>
      _isDeliveryConfirmedForCurrentOrder;
  bool isEstimating(String restaurantId) =>
      _loadingEstimations.contains(restaurantId);
  OrderEstimation? estimationFor(String restaurantId) =>
      _estimationsByRestaurant[restaurantId];
  bool hasEstimationFor(String restaurantId) =>
      _estimationsByRestaurant.containsKey(restaurantId);
  bool get hasCustomerPosition => _customerPosition != null;
  bool get hasDeliveryAddressForEstimation =>
      (deliveryAddress ?? '').trim().isNotEmpty;

  Future<void> openUserCartBox(String userId) async {
    if (_currentUserId == userId && _userCartBox != null) return;
    if (_userCartBox != null && _currentUserId != userId) {
      await _userCartBox!.close();
      _items.clear();
    }
    _currentUserId = userId;

    final boxName = 'cartBox_$userId';
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<CartItem>(boxName);
    }
    _userCartBox = Hive.box<CartItem>(boxName);

    _items
      ..clear()
      ..addAll(_userCartBox!.values.toList());

    _delivery = _deliveryBox.get('current');
    _isDeliveryConfirmedForCurrentOrder = false;
    _estimationsByRestaurant.clear();
    _restaurantLocations.clear();
    _unavailableItemNamesByRestaurant.clear();
    _lastEstimateSignatureByRestaurant.clear();
    _loadingEstimations.clear();
    notifyListeners();
  }

  Future<void> refreshCartImages() async {
    final restaurantIds = _items
        .map((item) => item.product.restaurantId)
        .where((id) => id.isNotEmpty)
        .toSet();

    for (final restaurantId in restaurantIds) {
      await refreshCartImagesForRestaurant(restaurantId);
    }
  }

  Future<void> refreshCartImagesForRestaurant(String restaurantId) async {
    if (_userCartBox == null ||
        _refreshingImageRestaurants.contains(restaurantId)) {
      return;
    }

    final hasItemsForRestaurant = _items.any(
      (item) => item.product.restaurantId == restaurantId,
    );
    if (!hasItemsForRestaurant) return;

    _refreshingImageRestaurants.add(restaurantId);

    try {
      final restaurantData = await _restaurantService.fetchRestaurant(
        restaurantId,
      );
      final freshImageUrls = extractRestaurantItemImageUrls(restaurantData);
      if (freshImageUrls.isEmpty) return;

      var changed = false;
      for (var i = 0; i < _items.length; i++) {
        final item = _items[i];
        if (item.product.restaurantId != restaurantId) continue;

        final freshImageUrl = freshImageUrls[item.product.id];
        if (freshImageUrl == null || freshImageUrl.isEmpty) continue;
        if (freshImageUrl == item.product.imageUrl) continue;

        _items[i] = CartItem(
          product: item.product.copyWith(imageUrl: freshImageUrl),
          quantity: item.quantity,
          menuBasePrice: item.menuBasePrice,
          selectedMenuItems: item.selectedMenuItems,
        );
        changed = true;
      }

      if (changed) {
        _saveCart();
        notifyListeners();
      }
    } catch (e, stack) {
      logger.e(
        '[CartImages] Failed to refresh cart images for restaurantId=$restaurantId',
        error: e,
        stackTrace: stack,
      );
    } finally {
      _refreshingImageRestaurants.remove(restaurantId);
    }
  }

  Future<void> closeUserCartBox() async {
    if (_userCartBox != null) {
      await _userCartBox!.close();
      _userCartBox = null;
      _items.clear();
      _isDeliveryConfirmedForCurrentOrder = false;
      _currentUserId = null;
      _estimationsByRestaurant.clear();
      _restaurantLocations.clear();
      _unavailableItemNamesByRestaurant.clear();
      _lastEstimateSignatureByRestaurant.clear();
      _loadingEstimations.clear();
      notifyListeners();
    }
  }

  void _saveCart() {
    if (_userCartBox == null) return;
    _userCartBox!.clear();
    for (var item in _items) {
      _userCartBox!.add(item);
    }
  }

  void addProduct(
    Product product, {
    required String restaurantId,
    required String restaurantName,
    int quantity = 1,
  }) {
    if (_userCartBox == null) return;
    _restaurantId ??= restaurantId;
    _restaurantName ??= restaurantName;

    final enrichedProduct = product.copyWith(
      restaurantId: product.restaurantId.isEmpty ? restaurantId : null,
      restaurantName: product.restaurantName.isEmpty ? restaurantName : null,
    );

    final index = _items.indexWhere(
      (item) => !item.isConfiguredItem && item.product.id == enrichedProduct.id,
    );
    if (index != -1) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(product: enrichedProduct, quantity: quantity));
    }
    _clearUnavailableItemsForRestaurant(restaurantId);
    _saveCart();
    notifyListeners();
  }

  void addConfiguredMenu({
    required Product menuProduct,
    required List<SelectedMenuItem> selectedItems,
    required double menuBasePrice,
    required String restaurantId,
    required String restaurantName,
    int quantity = 1,
  }) {
    if (_userCartBox == null) return;
    _restaurantId ??= restaurantId;
    _restaurantName ??= restaurantName;

    final enrichedProduct = menuProduct.copyWith(
      restaurantId: menuProduct.restaurantId.isEmpty ? restaurantId : null,
      restaurantName: menuProduct.restaurantName.isEmpty
          ? restaurantName
          : null,
      canBeSoldAlone: false,
    );

    final signature = _menuSelectionSignature(selectedItems);
    final index = _items.indexWhere(
      (item) =>
          item.isConfiguredMenu &&
          item.product.id == enrichedProduct.id &&
          _menuSelectionSignature(item.selectedMenuItems!) == signature,
    );

    if (index != -1) {
      _items[index].quantity += quantity;
    } else {
      _items.add(
        CartItem(
          product: enrichedProduct,
          quantity: quantity,
          menuBasePrice: menuBasePrice,
          selectedMenuItems: List.from(selectedItems),
        ),
      );
    }
    _clearUnavailableItemsForRestaurant(restaurantId);
    _saveCart();
    notifyListeners();
  }

  void addConfiguredProduct({
    required Product product,
    required List<SelectedMenuItem> selectedItems,
    required double basePrice,
    required String restaurantId,
    required String restaurantName,
    int quantity = 1,
  }) {
    if (_userCartBox == null) return;
    _restaurantId ??= restaurantId;
    _restaurantName ??= restaurantName;

    final enrichedProduct = product.copyWith(
      restaurantId: product.restaurantId.isEmpty ? restaurantId : null,
      restaurantName: product.restaurantName.isEmpty ? restaurantName : null,
    );

    final signature = _menuSelectionSignature(selectedItems);
    final index = _items.indexWhere(
      (item) =>
          item.isConfiguredProduct &&
          item.product.id == enrichedProduct.id &&
          _menuSelectionSignature(item.selectedMenuItems!) == signature,
    );

    if (index != -1) {
      _items[index].quantity += quantity;
    } else {
      _items.add(
        CartItem(
          product: enrichedProduct,
          quantity: quantity,
          menuBasePrice: basePrice,
          selectedMenuItems: List.from(selectedItems),
        ),
      );
    }
    _clearUnavailableItemsForRestaurant(restaurantId);
    _saveCart();
    notifyListeners();
  }

  String _menuSelectionSignature(List<SelectedMenuItem> items) {
    final sorted = List<SelectedMenuItem>.from(items)
      ..sort((a, b) {
        final byGroup = a.groupId.compareTo(b.groupId);
        if (byGroup != 0) return byGroup;
        return a.menuItemId.compareTo(b.menuItemId);
      });
    return sorted
        .map(
          (item) =>
              '${item.groupId}:${item.menuItemId}:${item.productId}:'
              '${item.additionalPrice}:${item.productChoicesJson}',
        )
        .join('|');
  }

  void incrementQuantity(Product product) {
    if (_userCartBox == null) return;
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      _items[index].quantity++;
      _clearUnavailableItemsForRestaurant(product.restaurantId);
      _saveCart();
      _scheduleEstimationForRestaurant(product.restaurantId);
      notifyListeners();
    }
  }

  void incrementItem(CartItem item) {
    if (_userCartBox == null) return;
    final index = _items.indexOf(item);
    if (index != -1) {
      _items[index].quantity++;
      _clearUnavailableItemsForRestaurant(item.product.restaurantId);
      _saveCart();
      _scheduleEstimationForRestaurant(item.product.restaurantId);
      notifyListeners();
    }
  }

  void decrementQuantity(CartItem item) {
    if (_userCartBox == null) return;
    final index = _items.indexOf(item);
    if (index != -1 && _items[index].quantity > 1) {
      _items[index].quantity--;
      _clearUnavailableItemsForRestaurant(item.product.restaurantId);
      _saveCart();
      _scheduleEstimationForRestaurant(item.product.restaurantId);
      notifyListeners();
    }
  }

  void decrementQuantityByProduct(Product product) {
    if (_userCartBox == null) return;
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index != -1 && _items[index].quantity > 1) {
      _items[index].quantity--;
      _clearUnavailableItemsForRestaurant(product.restaurantId);
      _saveCart();
      _scheduleEstimationForRestaurant(product.restaurantId);
      notifyListeners();
    }
  }

  void removeProduct(Product product) {
    if (_userCartBox == null) return;
    _items.removeWhere((item) => item.product.id == product.id);
    _clearUnavailableItemsForRestaurant(product.restaurantId);
    _saveCart();
    _scheduleEstimationForRestaurant(product.restaurantId);
    notifyListeners();
  }

  void removeItem(CartItem item) {
    if (_userCartBox == null) return;
    _items.remove(item);
    _clearUnavailableItemsForRestaurant(item.product.restaurantId);
    _saveCart();
    _scheduleEstimationForRestaurant(item.product.restaurantId);
    notifyListeners();
  }

  void setDeliveryContact(DeliveryAddress delivery) {
    _delivery = delivery;
    _isDeliveryConfirmedForCurrentOrder = true;
    _deliveryBox.put('current', delivery);
    _scheduleEstimationForAllRestaurants();
    notifyListeners();
  }

  void clearDeliveryAddress() {
    _delivery = null;
    _isDeliveryConfirmedForCurrentOrder = false;
    _deliveryBox.delete('current');
    _estimationsByRestaurant.clear();
    _restaurantLocations.clear();
    _unavailableItemNamesByRestaurant.clear();
    _lastEstimateSignatureByRestaurant.clear();
    notifyListeners();
  }

  void consumeDeliveryConfirmation() {
    if (!_isDeliveryConfirmedForCurrentOrder) return;
    _isDeliveryConfirmedForCurrentOrder = false;
    notifyListeners();
  }

  Future<void> clearCart() async {
    if (_userCartBox == null) return;
    _items.clear();
    commentController.clear();
    _restaurantId = null;
    _restaurantName = null;
    _isDeliveryConfirmedForCurrentOrder = false;
    _estimationsByRestaurant.clear();
    _restaurantLocations.clear();
    _unavailableItemNamesByRestaurant.clear();
    _lastEstimateSignatureByRestaurant.clear();
    _saveCart();
    notifyListeners();
  }

  void updateCustomerPosition(LatLng? position) {
    final changed =
        _customerPosition?.latitude != position?.latitude ||
        _customerPosition?.longitude != position?.longitude;

    _customerPosition = position;
    if (changed) {
      _scheduleEstimationForAllRestaurants();
    }
  }

  double? subtotalFor(CartGroup group) =>
      estimationFor(group.restaurantId)?.subtotal;

  double? serviceFeeFor(CartGroup group) =>
      estimationFor(group.restaurantId)?.serviceFee;

  double? deliveryFeeFor(CartGroup group) =>
      estimationFor(group.restaurantId)?.deliveryFee;

  double? totalFor(CartGroup group) => estimationFor(group.restaurantId)?.total;

  bool canEstimateFor(CartGroup group) =>
      group.items.isNotEmpty &&
      hasCustomerPosition &&
      hasDeliveryAddressForEstimation;

  Cart get cart => Cart(
    items: _items,
    restaurantId: _restaurantId,
    deliveryAddress: _delivery?.displayLabel,
  );

  List<CartGroup> get groupedCarts {
    final Map<String, List<CartItem>> grouped = {};
    final Map<String, String> restaurantNames = {};

    for (final item in _items) {
      final id = item.product.restaurantId;
      final name = item.product.restaurantName;

      grouped.putIfAbsent(id, () => []).add(item);

      if ((restaurantNames[id] ?? '').isEmpty) {
        if (name.isNotEmpty) {
          restaurantNames[id] = name;
        } else if (_restaurantId == id && _restaurantName != null) {
          restaurantNames[id] = _restaurantName!;
        } else {
          restaurantNames[id] = 'Restaurant inconnu';
        }
      }
    }

    return grouped.entries.map((entry) {
      final restaurantId = entry.key;
      final items = entry.value;
      final restaurantName = restaurantNames[restaurantId] ?? '';

      return CartGroup(
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        deliveryAddress: _delivery?.displayLabel ?? '',
        items: items,
      );
    }).toList();
  }

  void removeCartGroup(String restaurantId) {
    if (_userCartBox == null) return;
    _items.removeWhere((item) => item.product.restaurantId == restaurantId);
    _estimationsByRestaurant.remove(restaurantId);
    _unavailableItemNamesByRestaurant.remove(restaurantId);
    _lastEstimateSignatureByRestaurant.remove(restaurantId);
    _loadingEstimations.remove(restaurantId);
    _isDeliveryConfirmedForCurrentOrder = false;
    _saveCart();
    notifyListeners();
  }

  void markUnavailableItems(String restaurantId, List<String> itemNames) {
    final normalizedNames = itemNames
        .map(_normalizeUnavailableItemName)
        .where((name) => name.isNotEmpty)
        .toSet();
    if (normalizedNames.isEmpty) return;

    _unavailableItemNamesByRestaurant[restaurantId] = normalizedNames;
    notifyListeners();
  }

  bool isUnavailableItem(CartItem item) {
    final restaurantNames =
        _unavailableItemNamesByRestaurant[item.product.restaurantId];
    if (restaurantNames == null || restaurantNames.isEmpty) return false;
    return restaurantNames.contains(
      _normalizeUnavailableItemName(item.product.name),
    );
  }

  void clearUnavailableItemsForRestaurant(String restaurantId) {
    if (!_unavailableItemNamesByRestaurant.containsKey(restaurantId)) return;
    _unavailableItemNamesByRestaurant.remove(restaurantId);
    notifyListeners();
  }

  void _clearUnavailableItemsForRestaurant(String restaurantId) {
    _unavailableItemNamesByRestaurant.remove(restaurantId);
  }

  String _normalizeUnavailableItemName(String value) =>
      value.trim().toLowerCase();

  void _scheduleEstimationForAllRestaurants() {
    if (groupedCarts.isEmpty) return;
    for (final group in groupedCarts) {
      _scheduleEstimationForRestaurant(group.restaurantId);
    }
  }

  void _scheduleEstimationForRestaurant(String restaurantId) {
    _estimateDebounces[restaurantId]?.cancel();
    _estimateDebounces[restaurantId] = Timer(
      const Duration(milliseconds: 450),
      () {
        estimateForRestaurant(restaurantId);
      },
    );
  }

  Future<void> estimateForRestaurant(String restaurantId) async {
    if (_loadingEstimations.contains(restaurantId)) {
      return;
    }

    CartGroup? group;
    for (final candidate in groupedCarts) {
      if (candidate.restaurantId == restaurantId) {
        group = candidate;
        break;
      }
    }
    if (group == null || !canEstimateFor(group)) {
      _estimationsByRestaurant.remove(restaurantId);
      return;
    }

    final signature = _buildEstimateSignature(group);
    if (_lastEstimateSignatureByRestaurant[restaurantId] == signature) {
      return;
    }

    _loadingEstimations.add(restaurantId);
    notifyListeners();

    try {
      final restaurantLocation = await _getRestaurantLocation(restaurantId);
      if (restaurantLocation == null) {
        _loadingEstimations.remove(restaurantId);
        notifyListeners();
        return;
      }

      final data = await _orderService.estimateOrder(
        items: group.estimationItems,
        restaurantLocation: restaurantLocation,
        customerLocation: {
          'latitude': _customerPosition!.latitude,
          'longitude': _customerPosition!.longitude,
        },
      );

      _estimationsByRestaurant[restaurantId] = OrderEstimation.fromJson(data);
      _lastEstimateSignatureByRestaurant[restaurantId] = signature;
    } on OrderEstimationException catch (e) {
      _estimationsByRestaurant.remove(restaurantId);
      logger.e(
        '[CartEstimation] API error for restaurantId=$restaurantId '
        '(status=${e.statusCode})',
        error: e.body,
      );
    } catch (e, stack) {
      _estimationsByRestaurant.remove(restaurantId);
      logger.e(
        '[CartEstimation] Unexpected error for restaurantId=$restaurantId',
        error: e,
        stackTrace: stack,
      );
    } finally {
      _loadingEstimations.remove(restaurantId);
      notifyListeners();
    }
  }

  String _buildEstimateSignature(CartGroup group) {
    final itemSignature = group.items
        .map((item) => '${item.product.id}:${item.quantity}:${item.unitPrice}')
        .join('|');
    return '$itemSignature@${_customerPosition!.latitude},${_customerPosition!.longitude}';
  }

  Future<Map<String, dynamic>?> _getRestaurantLocation(
    String restaurantId,
  ) async {
    final cached = _restaurantLocations[restaurantId];
    if (cached != null) {
      return cached;
    }

    final restaurantData = await _restaurantService.fetchRestaurant(
      restaurantId,
    );
    final extracted = _extractRestaurantLocation(restaurantData);
    if (extracted != null) {
      _restaurantLocations[restaurantId] = extracted;
    }
    return extracted;
  }

  Map<String, dynamic>? _extractRestaurantLocation(Map<String, dynamic> json) {
    final direct = _extractLatLng(json);
    if (direct != null) return direct;

    final location = json['location'];
    if (location is Map<String, dynamic>) {
      return _extractLatLng(location);
    }
    return null;
  }

  Map<String, dynamic>? _extractLatLng(Map<String, dynamic> source) {
    final latitude = (source['latitude'] ?? source['lat']) as num?;
    final longitude =
        (source['longitude'] ?? source['lng'] ?? source['lon']) as num?;
    if (latitude == null || longitude == null) return null;
    return {'latitude': latitude.toDouble(), 'longitude': longitude.toDouble()};
  }

  @override
  void dispose() {
    for (final timer in _estimateDebounces.values) {
      timer.cancel();
    }
    _estimateDebounces.clear();
    commentController.dispose();
    super.dispose();
  }
}
