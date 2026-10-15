import 'dart:async';

import 'package:dineroo_mobile/driver/enums/driver_ride_phase.dart';
import 'package:dineroo_mobile/driver/enums/delivery_status.dart';
import 'package:dineroo_mobile/driver/enums/driver_ui_transition.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dineroo_mobile/driver/enums/driver_status.dart';
import 'package:dineroo_mobile/customer/repositories/restaurant_repository.dart';
import 'package:dineroo_mobile/driver/repositories/driver_presence_repository.dart';
import 'package:dineroo_mobile/shared/common/utils/map_query_builder.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/driver/models/domain/driver_delivery_event.dart';
import 'package:dineroo_mobile/driver/models/domain/driver_delivery.dart';
import 'package:dineroo_mobile/driver/repositories/driver_delivery_repository.dart';
import 'package:dineroo_mobile/driver/repositories/driver_order_repository.dart';
import 'package:dineroo_mobile/shared/models/domain/order.dart';
import 'package:dineroo_mobile/shared/models/domain/order_details.dart';
import 'package:dineroo_mobile/shared/models/domain/contact.dart';
import 'package:dineroo_mobile/shared/common/factories/contact_factory.dart';
import 'package:dineroo_mobile/driver/models/domain/external_map_destination.dart';

typedef PickupPositionProvider = Future<PickupPosition> Function();

class PickupPosition {
  const PickupPosition({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class DriverHomeViewModel extends ChangeNotifier {
  final DriverPresenceRepository _presenceRepo;
  final DriverDeliveryRepository _deliveryRepo;
  final DriverOrderRepository _driverOrderRepo;
  final RestaurantRepository _restaurantRepository;
  final CurrentUserViewModel _currentUserVM;
  final PickupPositionProvider _pickupPositionProvider;

  DriverHomeViewModel(
    this._presenceRepo,
    this._deliveryRepo,
    this._driverOrderRepo,
    this._restaurantRepository,
    this._currentUserVM, {
    PickupPositionProvider? pickupPositionProvider,
  }) : _pickupPositionProvider =
           pickupPositionProvider ?? _getCurrentPickupPosition;

  bool isOnline = false;
  bool isOnRide = false;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingOrderDetails = false;
  bool get isLoadingOrderDetails => _isLoadingOrderDetails;

  String? _error;
  String? get error => _error;

  DriverRidePhase _ridePhase = DriverRidePhase.idle;
  DriverRidePhase get ridePhase => _ridePhase;

  DriverUiTransition? _pendingUiTransition;

  String? _activeDeliveryId;
  String? get activeDeliveryId => _activeDeliveryId;

  DriverDeliveryEvent? _currentDelivery;
  DriverDeliveryEvent? get currentDelivery => _currentDelivery;

  Order? _currentOrder;
  Order? get currentOrder => _currentOrder;

  OrderDetails? _currentOrderDetails;
  OrderDetails? get currentOrderDetails => _currentOrderDetails;

  String? _restaurantPhone;
  String? get restaurantPhone => _restaurantPhone;

  String? _pickupOtpCode;
  String? get pickupOtpCode => _pickupOtpCode;

  String? get currentOrderId => _currentDelivery?.orderId;

  String? get _driverId => _currentUserVM.currentUser?.id;

  bool get canStartRide => isOnline && isOnRide;
  bool get isHeadingToRestaurant => _ridePhase == DriverRidePhase.toRestaurant;
  bool get isHeadingToCustomer => _ridePhase == DriverRidePhase.toCustomer;

  String get restaurantName {
    final fromSocket = _currentDelivery?.restaurantName.trim() ?? '';
    if (fromSocket.isNotEmpty) return fromSocket;

    final fromOrder = _currentOrder?.restaurantName.trim() ?? '';
    if (fromOrder.isNotEmpty) return fromOrder;

    return 'Restaurant';
  }

  String get pickupAddress {
    final fromSocket = _currentDelivery?.pickupAddress.trim() ?? '';
    if (fromSocket.isNotEmpty) return fromSocket;
    return '';
  }

  String get deliveryAddress {
    final contact = _currentOrder?.deliveryContact;

    if (contact != null) {
      final parts = [
        contact.address.trim(),
        contact.district?.trim(),
        contact.commune?.trim(),
        contact.instructions?.trim(),
      ].where((e) => e != null && e.isNotEmpty).cast<String>().toList();

      if (parts.isNotEmpty) {
        return parts.join(', ');
      }
    }

    final fromSocket = _currentDelivery?.deliveryAddress.trim() ?? '';
    if (fromSocket.isNotEmpty) return fromSocket;

    return '';
  }

  double get deliveryFee => _currentDelivery?.deliveryFee.toDouble() ?? 0;

  double get estimatedDeliveryDistance =>
      _currentDelivery?.estimatedDeliveryDistance.toDouble() ?? 0;

  String get estimatedDeliveryDistanceLabel =>
      'à ${estimatedDeliveryDistance.toStringAsFixed(1)} km';

  String get customerName {
    final fromOrder =
        _currentOrder?.deliveryContact.shortDisplayName.trim() ?? '';
    if (fromOrder.isNotEmpty && fromOrder != 'Client') {
      return fromOrder;
    }

    final customer = _currentOrderDetails?.customerDetails;
    if (customer != null) {
      return ContactFactory.publicCustomer(
        fullName: customer.displayName,
        phoneNumber: customer.phone,
      ).displayName;
    }
    return 'Client';
  }

  String get customerPhone {
    final fromOrder = _currentOrder?.deliveryContact.phoneNumber.trim() ?? '';
    if (fromOrder.isNotEmpty) return fromOrder;

    final fromDetails =
        _currentOrderDetails?.customerDetails?.phone.trim() ?? '';
    if (fromDetails.isNotEmpty) return fromDetails;

    return '';
  }

  Contact? get driverContact {
    final driver = _currentOrderDetails?.driverDetails;
    if (driver == null) return null;

    return ContactFactory.publicDriver(
      fullName: driver.fullName,
      phoneNumber: driver.phoneNumber,
    );
  }

  ExternalMapDestination get restaurantMapDestination {
    return ExternalMapDestination(
      label: restaurantName.isNotEmpty ? restaurantName : 'Restaurant',
      query: MapQueryBuilder.buildRestaurantQuery(
        restaurantName: restaurantName,
        pickupAddress: pickupAddress,
      ),
    );
  }

  ExternalMapDestination get clientMapDestination {
    final contact = _currentOrder?.deliveryContact;
    return ExternalMapDestination(
      label: MapQueryBuilder.buildClientLabel(contact),
      query: MapQueryBuilder.buildClientQuery(contact),
    );
  }

  ExternalMapDestination get currentMapDestination =>
      isHeadingToCustomer ? clientMapDestination : restaurantMapDestination;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setOrderLoading(bool value) {
    _isLoadingOrderDetails = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  void _setPendingUiTransition(DriverUiTransition command) {
    _pendingUiTransition = command;
    logger.i(
      '[DriverUI] Pending transition set: $command '
      '(active=$_activeDeliveryId, isOnRide=$isOnRide, phase=$_ridePhase)',
    );
    notifyListeners();
  }

  DriverUiTransition? consumePendingUiTransition() {
    final command = _pendingUiTransition;
    _pendingUiTransition = null;
    return command;
  }

  void _updateDriverPresence(DriverStatus status) {
    switch (status) {
      case DriverStatus.online:
        isOnline = true;
        isOnRide = false;
        _ridePhase = DriverRidePhase.idle;
        break;
      case DriverStatus.onDelivery:
        isOnline = true;
        isOnRide = true;
        break;
      case DriverStatus.offline:
        isOnline = false;
        isOnRide = false;
        _clearRideData();
        break;
    }
  }

  Future<void> goOnline() async {
    final driverId = _driverId;
    if (driverId == null || driverId.isEmpty) {
      _setError("Impossible de passer en ligne.");
      return;
    }
    if (_isLoading) return;

    _setError(null);
    _setLoading(true);

    try {
      final status = await _presenceRepo.setStatus(
        driverId: driverId,
        status: DriverStatus.online,
      );
      logger.i('[DriverPresence] goOnline success');

      _updateDriverPresence(status);
    } catch (e, stack) {
      logger.e('[DriverPresence] goOnline failed', error: e, stackTrace: stack);
      _setError("Impossible de passer en ligne.");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> restoreDriverSessionFromBackend() async {
    final driverId = _driverId;
    if (driverId == null || driverId.isEmpty) return;

    _setError(null);
    _setLoading(true);

    try {
      final status = await _presenceRepo.fetchStatus(driverId: driverId);
      _updateDriverPresence(status);

      final deliveries = await _deliveryRepo.fetchDeliveriesByDriverId(
        driverId: driverId,
        statuses: const ['ASSIGNED', 'PICKED_UP'],
      );

      final currentDelivery = _selectCurrentDelivery(deliveries);
      if (currentDelivery == null) {
        if (status == DriverStatus.onDelivery) {
          isOnline = true;
          isOnRide = false;
          _ridePhase = DriverRidePhase.idle;
        }
        notifyListeners();
        return;
      }

      _activeDeliveryId = currentDelivery.id;
      _pickupOtpCode = currentDelivery.pickupOtpCode;
      isOnline = true;
      isOnRide = true;

      final orderId = currentDelivery.orderId;
      if (orderId.isNotEmpty) {
        await _loadCurrentOrderData(orderId);
      }

      final event = DriverDeliveryEvent(
        deliveryId: currentDelivery.id,
        orderId: currentDelivery.orderId,
        deliveryAddress: _currentOrder?.deliveryAddress ?? '',
        pickupAddress: currentDelivery.pickupAddressLabel,
        restaurantName: _currentOrder?.restaurantName ?? 'Restaurant',
        estimatedDeliveryDistance: currentDelivery.estimatedDeliveryDistance ?? 0,
        deliveryFee: currentDelivery.deliveryFee ?? 0,
        driverIds: [driverId],
      );

      _currentDelivery = event;

      if (currentDelivery.status == DeliveryStatus.pickedUp) {
        _ridePhase = DriverRidePhase.toCustomer;
        _setPendingUiTransition(DriverUiTransition.showCustomerDialog);
      } else {
        _ridePhase = DriverRidePhase.toRestaurant;
        _setPendingUiTransition(DriverUiTransition.showRestaurantDialog);
      }
    } catch (e, stack) {
      logger.e('[DriverSession] restore failed', error: e, stackTrace: stack);
      _setError('Impossible de restaurer votre session livreur.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> goOffline() async {
    if (isOnRide) {
      _setError("Impossible de passer hors ligne pendant une course.");
      return;
    }

    final driverId = _driverId;
    if (driverId == null || driverId.isEmpty) {
      _setError("Impossible de passer hors ligne.");
      return;
    }
    if (_isLoading) return;

    _setError(null);
    _setLoading(true);

    try {
      final status = await _presenceRepo.setStatus(
        driverId: driverId,
        status: DriverStatus.offline,
      );

      logger.i('[DriverPresence] goOffline success');
      _updateDriverPresence(status);
    } catch (e, stack) {
      logger.e(
        '[DriverPresence] goOffline failed',
        error: e,
        stackTrace: stack,
      );
      _setError("Impossible de passer hors ligne.");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> acceptIncomingRide() async {
    final driverId = _driverId;
    final deliveryId = _activeDeliveryId;
    final orderId = _currentDelivery?.orderId;

    if (driverId == null || driverId.isEmpty) {
      _setError("Impossible d'accepter la course.");
      return;
    }

    if (deliveryId == null || deliveryId.isEmpty) {
      _setError("Impossible d'accepter la course : livraison introuvable.");
      return;
    }

    if (orderId == null || orderId.isEmpty) {
      _setError("Impossible d'accepter la course : commande introuvable.");
      return;
    }

    if (_isLoading) return;

    _setError(null);
    _setLoading(true);

    try {
      await _deliveryRepo.assignDriver(
        driverId: driverId,
        deliveryId: deliveryId,
      );

      final assignedDelivery = await _findAssignedDeliveryForEvent(
        driverId: driverId,
        deliveryId: deliveryId,
      );
      _pickupOtpCode = assignedDelivery?.pickupOtpCode;

      final status = await _presenceRepo.setStatus(
        driverId: driverId,
        status: DriverStatus.onDelivery,
      );

      logger.i('[DriverRide] acceptIncomingRide success');

      _updateDriverPresence(status);
      _ridePhase = DriverRidePhase.toRestaurant;

      await _loadCurrentOrderData(orderId);

      _setPendingUiTransition(DriverUiTransition.showRestaurantDialog);
    } catch (e, stack) {
      logger.e(
        '[DriverRide] acceptIncomingRide failed',
        error: e,
        stackTrace: stack,
      );
      _setError("Impossible d'accepter la course.");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadCurrentOrderData(String orderId) async {
    _setOrderLoading(true);

    try {
      Order? fetchedOrder;
      OrderDetails? fetchedOrderDetails;

      try {
        fetchedOrder = await _driverOrderRepo.fetchOrderById(orderId);
      } catch (e, stack) {
        logger.w(
          '[DriverRide] Failed to fetch order by id',
          error: e,
          stackTrace: stack,
        );
      }

      try {
        fetchedOrderDetails = await _driverOrderRepo.fetchOrderDetails(orderId);
      } catch (e, stack) {
        logger.w(
          '[DriverRide] Failed to fetch order details',
          error: e,
          stackTrace: stack,
        );
      }

      if (fetchedOrder == null) {
        logger.w(
          '[DriverRide] Order data unavailable, using realtime payload only',
        );
        return;
      }

      _currentOrder = fetchedOrder;
      _currentOrderDetails = fetchedOrderDetails;

      final restaurantId = _currentOrder?.restaurantId.trim() ?? '';
      if (restaurantId.isNotEmpty) {
        try {
          final restaurant = await _restaurantRepository.getRestaurant(
            restaurantId,
          );
          final resolvedRestaurantName = restaurant.name.trim();
          if (resolvedRestaurantName.isNotEmpty && _currentOrder != null) {
            _currentOrder = _currentOrder!.copyWith(
              restaurantName: resolvedRestaurantName,
            );

            if (_currentDelivery != null &&
                _currentDelivery!.restaurantName.trim().isEmpty) {
              _currentDelivery = _currentDelivery!.copyWith(
                restaurantName: resolvedRestaurantName,
              );
            }
          }

          _restaurantPhone = restaurant.phone.trim().isNotEmpty
              ? restaurant.phone.trim()
              : null;
        } catch (e, stack) {
          logger.w(
            '[DriverRide] Failed to load restaurant phone',
            error: e,
            stackTrace: stack,
          );
          _restaurantPhone = null;
        }
      } else {
        _restaurantPhone = null;
      }

      logger.i(
        '[DriverRide] Loaded order data for $orderId '
        '(driverAssigned=${_currentOrderDetails?.hasAssignedDriver ?? false})',
      );
    } catch (e, stack) {
      logger.e(
        '[DriverRide] Failed to load order data',
        error: e,
        stackTrace: stack,
      );
    } finally {
      _setOrderLoading(false);
    }
  }

  Future<String?> moveToCustomerStep() async {
    final deliveryId = _activeDeliveryId;
    if (_currentDelivery == null || deliveryId == null || deliveryId.isEmpty) {
      return 'Impossible de confirmer la récupération de la commande.';
    }

    _setLoading(true);
    try {
      final position = await _pickupPositionProvider();
      await _deliveryRepo.updateDeliveryStatus(
        deliveryId: deliveryId,
        status: DeliveryStatus.pickedUp.apiValue,
        driverId: _driverId,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      _ridePhase = DriverRidePhase.toCustomer;
      _setPendingUiTransition(DriverUiTransition.showCustomerDialog);
      return null;
    } catch (e, stack) {
      logger.e(
        '[DriverRide] moveToCustomerStep failed',
        error: e,
        stackTrace: stack,
      );
      final message = e.toString();
      if (message.contains('Veuillez demander au restaurant')) {
        return 'Veuillez demander au restaurant de valider votre code de récupération.';
      } else if (message.contains('proximité du restaurant')) {
        return 'Vous devez être à proximité du restaurant pour récupérer cette commande.';
      } else if (message.contains('PICKED_UP to PICKED_UP')) {
        _ridePhase = DriverRidePhase.toCustomer;
        _setPendingUiTransition(DriverUiTransition.showCustomerDialog);
        return null;
      } else {
        return 'Impossible de confirmer la récupération de la commande.';
      }
    } finally {
      _setLoading(false);
    }
  }

  void completeRideLocally() {
    _ridePhase = DriverRidePhase.idle;
    isOnRide = false;
    _activeDeliveryId = null;
    _currentDelivery = null;
    _currentOrder = null;
    _currentOrderDetails = null;
    _restaurantPhone = null;
    _pickupOtpCode = null;
    notifyListeners();
  }

  Future<void> completeRide() async {
    final deliveryId = _activeDeliveryId;
    if (deliveryId == null || deliveryId.isEmpty) {
      completeRideLocally();
      return;
    }

    _setLoading(true);
    _setError(null);
    try {
      await _deliveryRepo.updateDeliveryStatus(
        deliveryId: deliveryId,
        status: DeliveryStatus.delivered.apiValue,
      );
      completeRideLocally();
    } catch (e, stack) {
      logger.e('[DriverRide] completeRide failed', error: e, stackTrace: stack);
      _setError('Impossible de confirmer la livraison.');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void handleRealtimeDelivery(DriverDeliveryEvent event) {
    unawaited(_handleRealtimeDeliveryAsync(event));
  }

  Future<void> _handleRealtimeDeliveryAsync(DriverDeliveryEvent event) async {
    logger.i(
      '[DriverRealtime] Delivery event received: ${event.deliveryId} '
      '(active=$_activeDeliveryId, isOnRide=$isOnRide, phase=$_ridePhase)',
    );

    if (isOnRide && _activeDeliveryId != event.deliveryId) {
      logger.w(
        '[DriverRealtime] Driver already on another ride, incoming delivery ignored '
        '(active=$_activeDeliveryId, incoming=${event.deliveryId})',
      );
      return;
    }

    if (_activeDeliveryId == event.deliveryId && _currentDelivery != null) {
      logger.i('[DriverRealtime] Same active delivery updated');
      _currentDelivery = event;
      notifyListeners();
      return;
    }

    final driverId = _driverId;
    if (driverId != null && driverId.isNotEmpty) {
      try {
        var assignedDelivery = await _findAssignedDeliveryForEvent(
          driverId: driverId,
          deliveryId: event.deliveryId,
        );

        if (assignedDelivery == null && !isOnline) {
          await Future<void>.delayed(const Duration(milliseconds: 700));
          assignedDelivery = await _findAssignedDeliveryForEvent(
            driverId: driverId,
            deliveryId: event.deliveryId,
          );
        }

        if (assignedDelivery != null) {
          if (!isOnline) {
            logger.i(
              '[DriverRealtime] Driver locally offline but delivery is assigned in backend, forcing local session sync',
            );
          }
          _activeDeliveryId = assignedDelivery.id;
          _pickupOtpCode = assignedDelivery.pickupOtpCode;
          isOnline = true;
          isOnRide = true;

          if (assignedDelivery.orderId.isNotEmpty) {
            await _loadCurrentOrderData(assignedDelivery.orderId);
          }

          _currentDelivery = event.copyWith(
            pickupAddress: assignedDelivery.pickupAddressLabel,
            deliveryAddress: assignedDelivery.deliveryAddressLabel,
            estimatedDeliveryDistance: assignedDelivery.estimatedDeliveryDistance ?? event.estimatedDeliveryDistance,
            deliveryFee: assignedDelivery.deliveryFee ?? event.deliveryFee,
          );

          if (assignedDelivery.status == DeliveryStatus.pickedUp) {
            _ridePhase = DriverRidePhase.toCustomer;
            _setPendingUiTransition(DriverUiTransition.showCustomerDialog);
          } else {
            _ridePhase = DriverRidePhase.toRestaurant;
            _setPendingUiTransition(DriverUiTransition.showRestaurantDialog);
          }
          return;
        }

        if (!isOnline) {
          logger.w(
            '[DriverRealtime] Driver offline and no assigned delivery found in backend, event ignored',
          );
          return;
        }
      } catch (e, stack) {
        logger.w(
          '[DriverRealtime] Failed to inspect delivery status, fallback to incoming dialog',
          error: e,
          stackTrace: stack,
        );
        if (!isOnline) {
          logger.w(
            '[DriverRealtime] Driver offline and backend check failed, event ignored',
          );
          return;
        }
      }
    } else if (!isOnline) {
      logger.w('[DriverRealtime] Driver offline, event ignored');
      return;
    }

    _activeDeliveryId = event.deliveryId;
    _currentDelivery = event;
    _ridePhase = DriverRidePhase.incoming;

    _enrichIncomingDeliveryFromBackend(
      deliveryId: event.deliveryId,
      orderId: event.orderId,
    );

    _setPendingUiTransition(DriverUiTransition.showIncomingRideDialog);
  }

  Future<DriverDelivery?> _findAssignedDeliveryForEvent({
    required String driverId,
    required String deliveryId,
  }) async {
    final deliveries = await _deliveryRepo.fetchDeliveriesByDriverId(
      driverId: driverId,
      statuses: const ['ASSIGNED', 'PICKED_UP'],
    );

    for (final delivery in deliveries) {
      if (delivery.id == deliveryId) {
        return delivery;
      }
    }

    return null;
  }

  void clearIncomingIfNotAccepted() {
    if (isOnRide) {
      logger.i(
        '[DriverRealtime] Skip clearing incoming delivery: driver already on ride',
      );
      return;
    }
    if (_ridePhase != DriverRidePhase.incoming && _currentDelivery == null) {
      return;
    }
    logger.i(
      '[DriverRealtime] Clearing pending incoming delivery '
      '(active=$_activeDeliveryId, phase=$_ridePhase)',
    );
    _activeDeliveryId = null;
    _currentDelivery = null;
    _ridePhase = DriverRidePhase.idle;
    notifyListeners();
  }

  Future<void> _enrichIncomingDeliveryFromBackend({
    required String deliveryId,
    required String orderId,
  }) async {
    final current = _currentDelivery;
    if (current == null) return;

    final needsEnrichment =
        current.restaurantName.trim().isEmpty ||
        current.pickupAddress.trim().isEmpty ||
        current.deliveryAddress.trim().isEmpty ||
        current.estimatedDeliveryDistance <= 0 ||
        current.deliveryFee <= 0;

    if (!needsEnrichment) return;

    try {
      String resolvedRestaurantName = current.restaurantName;
      String resolvedPickupAddress = current.pickupAddress;
      String resolvedDeliveryAddress = current.deliveryAddress;
      double resolvedDistance = current.estimatedDeliveryDistance;
      double resolvedFee = current.deliveryFee;

      final driverId = _driverId;
      if (driverId != null && driverId.isNotEmpty) {
        final deliveries = await _deliveryRepo.fetchDeliveriesByDriverId(
          driverId: driverId,
          statuses: const ['ASSIGNED', 'PICKED_UP'],
        );

        DriverDelivery? matchingDelivery;
        for (final delivery in deliveries) {
          if (delivery.id == deliveryId) {
            matchingDelivery = delivery;
            break;
          }
        }

        if (matchingDelivery != null) {
          _pickupOtpCode = matchingDelivery.pickupOtpCode ?? _pickupOtpCode;
          if (resolvedPickupAddress.trim().isEmpty) {
            final label = matchingDelivery.pickupAddressLabel.trim();
            if (label.isNotEmpty && label != '{}') {
              resolvedPickupAddress = label;
            }
          }

          if (resolvedDeliveryAddress.trim().isEmpty) {
            final label = matchingDelivery.deliveryAddressLabel.trim();
            if (label.isNotEmpty && label != '{}') {
              resolvedDeliveryAddress = label;
            }
          }

          if (resolvedDistance <= 0) {
            resolvedDistance = matchingDelivery.estimatedDeliveryDistance ?? 0;
          }

          if (resolvedFee <= 0) {
            resolvedFee = matchingDelivery.deliveryFee ?? 0;
          }
        }
      }

      final order = await _driverOrderRepo.fetchOrderById(orderId);

      if (resolvedRestaurantName.trim().isEmpty) {
        resolvedRestaurantName = order.restaurantName.trim();
      }

      if (resolvedRestaurantName.isEmpty) {
        final restaurant = await _restaurantRepository.getRestaurant(
          order.restaurantId,
        );
        resolvedRestaurantName = restaurant.name.trim();
      }

      if (_activeDeliveryId != deliveryId || _currentDelivery == null) return;

      _currentDelivery = _currentDelivery!.copyWith(
        restaurantName: resolvedRestaurantName,
        pickupAddress: resolvedPickupAddress,
        deliveryAddress: resolvedDeliveryAddress,
        estimatedDeliveryDistance: resolvedDistance,
        deliveryFee: resolvedFee,
      );
      notifyListeners();
    } catch (e, stack) {
      logger.w(
        '[DriverRealtime] Failed to enrich incoming delivery',
        error: e,
        stackTrace: stack,
      );
    }
  }

  void _clearRideData() {
    _activeDeliveryId = null;
    _currentDelivery = null;
    _pickupOtpCode = null;
    _currentOrder = null;
    _currentOrderDetails = null;
    _restaurantPhone = null;
    _ridePhase = DriverRidePhase.idle;
  }

  static Future<PickupPosition> _getCurrentPickupPosition() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception(
        'Vous devez être à proximité du restaurant pour récupérer cette commande.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return PickupPosition(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  DriverDelivery? _selectCurrentDelivery(List<DriverDelivery> deliveries) {
    if (deliveries.isEmpty) return null;

    final pickedUp = deliveries
        .where((d) => d.status == DeliveryStatus.pickedUp)
        .toList();
    if (pickedUp.isNotEmpty) {
      pickedUp.sort((a, b) {
        final ad = a.pickedUpAt ?? a.driverAssignedAt ?? a.createdAt;
        final bd = b.pickedUpAt ?? b.driverAssignedAt ?? b.createdAt;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return bd.compareTo(ad);
      });
      return pickedUp.first;
    }

    final assigned = deliveries
        .where((d) => d.status == DeliveryStatus.assigned)
        .toList();
    if (assigned.isNotEmpty) {
      assigned.sort((a, b) {
        final ad = a.driverAssignedAt ?? a.createdAt;
        final bd = b.driverAssignedAt ?? b.createdAt;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return bd.compareTo(ad);
      });
      return assigned.first;
    }

    return deliveries.first;
  }

  void resetDriverSessionLocal({bool notify = true}) {
    isOnline = false;
    isOnRide = false;
    _isLoading = false;
    _isLoadingOrderDetails = false;
    _error = null;
    _pendingUiTransition = null;
    _clearRideData();

    if (notify) {
      notifyListeners();
    }
  }

  Future<void> resetDriverSessionServer() async {
    try {
      if (isOnline && !isOnRide && !_isLoading) {
        final driverId = _driverId;
        if (driverId != null && driverId.isNotEmpty) {
          try {
            await _presenceRepo.setStatus(
              driverId: driverId,
              status: DriverStatus.offline,
            );
            logger.i(
              '[DriverPresence] resetDriverSessionServer backend OFFLINE',
            );
          } catch (e, stack) {
            logger.w(
              '[DriverPresence] resetDriverSessionServer backend offline failed',
              error: e,
              stackTrace: stack,
            );
          }
        }
      }
    } finally {
      resetDriverSessionLocal();
    }
  }
}
