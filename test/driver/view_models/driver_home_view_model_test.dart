import 'package:dineroo_mobile/customer/repositories/restaurant_repository.dart';
import 'package:dineroo_mobile/customer/services/restaurant/restaurant_list_service.dart';
import 'package:dineroo_mobile/customer/services/restaurant/restaurant_service.dart';
import 'package:dineroo_mobile/driver/enums/delivery_status.dart';
import 'package:dineroo_mobile/driver/enums/driver_ride_phase.dart';
import 'package:dineroo_mobile/driver/enums/driver_status.dart';
import 'package:dineroo_mobile/driver/enums/driver_ui_transition.dart';
import 'package:dineroo_mobile/driver/models/domain/driver_delivery_event.dart';
import 'package:dineroo_mobile/driver/repositories/driver_delivery_repository.dart';
import 'package:dineroo_mobile/driver/repositories/driver_order_repository.dart';
import 'package:dineroo_mobile/driver/repositories/driver_presence_repository.dart';
import 'package:dineroo_mobile/driver/services/delivery/driver_delivery_service.dart';
import 'package:dineroo_mobile/driver/services/driver_presence/driver_presence_service.dart';
import 'package:dineroo_mobile/driver/view_models/driver_home_view_model.dart';
import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:dineroo_mobile/shared/repositories/order_details_repository.dart';
import 'package:dineroo_mobile/shared/services/order/order_details_service.dart';
import 'package:dineroo_mobile/shared/services/order/shared_order_service.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DriverHomeViewModel', () {
    test('sets an error when going online without a driver id', () async {
      final harness = _Harness();

      await harness.viewModel.goOnline();

      expect(harness.viewModel.isOnline, isFalse);
      expect(harness.viewModel.error, 'Impossible de passer en ligne.');
      expect(harness.presence.updatedStatuses, isEmpty);
    });

    test('goes online and offline through the presence repository', () async {
      final harness = _Harness.withDriver();

      await harness.viewModel.goOnline();

      expect(harness.viewModel.isOnline, isTrue);
      expect(harness.viewModel.isOnRide, isFalse);
      expect(harness.presence.updatedStatuses, [DriverStatus.online.apiValue]);

      await harness.viewModel.goOffline();

      expect(harness.viewModel.isOnline, isFalse);
      expect(harness.viewModel.isOnRide, isFalse);
      expect(
        harness.presence.updatedStatuses.last,
        DriverStatus.offline.apiValue,
      );
    });

    test(
      'restores an assigned delivery and loads related order data',
      () async {
        final harness = _Harness.withDriver();
        harness.presence.status = DriverStatus.onDelivery;
        harness.delivery.deliveries = [_delivery(status: 'ASSIGNED')];

        await harness.viewModel.restoreDriverSessionFromBackend();

        expect(harness.viewModel.isOnline, isTrue);
        expect(harness.viewModel.isOnRide, isTrue);
        expect(harness.viewModel.activeDeliveryId, 'delivery-1');
        expect(harness.viewModel.ridePhase, DriverRidePhase.toRestaurant);
        expect(
          harness.viewModel.consumePendingUiTransition(),
          DriverUiTransition.showRestaurantDialog,
        );
        expect(harness.viewModel.restaurantName, 'Restaurant API');
        expect(harness.viewModel.restaurantPhone, '620000000');
        expect(harness.viewModel.deliveryAddress, 'Rue client, Kipé, Ratoma');
        expect(harness.viewModel.customerName, 'Aminata');
        expect(harness.viewModel.customerPhone, '621111111');
        expect(harness.viewModel.driverContact?.displayName, 'Mamadou');
        expect(
          harness.viewModel.restaurantMapDestination.label,
          'Restaurant API',
        );
        expect(
          harness.viewModel.clientMapDestination.label,
          'Aminata • Kipé • Ratoma',
        );
      },
    );

    test(
      'restores a picked up delivery directly to the customer step',
      () async {
        final harness = _Harness.withDriver();
        harness.presence.status = DriverStatus.onDelivery;
        harness.delivery.deliveries = [
          _delivery(
            id: 'older-assigned',
            status: 'ASSIGNED',
            assignedAt: '2026-01-01T09:00:00Z',
          ),
          _delivery(status: 'PICKED_UP', pickedUpAt: '2026-01-01T10:00:00Z'),
        ];

        await harness.viewModel.restoreDriverSessionFromBackend();

        expect(harness.viewModel.activeDeliveryId, 'delivery-1');
        expect(harness.viewModel.ridePhase, DriverRidePhase.toCustomer);
        expect(
          harness.viewModel.currentMapDestination.label,
          'Aminata • Kipé • Ratoma',
        );
        expect(
          harness.viewModel.consumePendingUiTransition(),
          DriverUiTransition.showCustomerDialog,
        );
      },
    );

    test('accepts an incoming ride then moves and completes it', () async {
      final harness = _Harness.withDriver();
      harness.viewModel.isOnline = true;
      harness.viewModel.handleRealtimeDelivery(_event());
      await _flushAsync();

      expect(harness.viewModel.ridePhase, DriverRidePhase.incoming);
      expect(
        harness.viewModel.consumePendingUiTransition(),
        DriverUiTransition.showIncomingRideDialog,
      );

      await harness.viewModel.acceptIncomingRide();

      expect(harness.delivery.assignedDriverIds, ['driver-1']);
      expect(harness.viewModel.isOnRide, isTrue);
      expect(harness.viewModel.ridePhase, DriverRidePhase.toRestaurant);
      expect(
        harness.viewModel.consumePendingUiTransition(),
        DriverUiTransition.showRestaurantDialog,
      );

      await harness.viewModel.moveToCustomerStep();

      expect(
        harness.delivery.updatedStatuses.last,
        DeliveryStatus.pickedUp.apiValue,
      );
      expect(harness.viewModel.ridePhase, DriverRidePhase.toCustomer);
      expect(
        harness.viewModel.consumePendingUiTransition(),
        DriverUiTransition.showCustomerDialog,
      );

      await harness.viewModel.completeRide();

      expect(
        harness.delivery.updatedStatuses.last,
        DeliveryStatus.delivered.apiValue,
      );
      expect(harness.viewModel.isOnRide, isFalse);
      expect(harness.viewModel.activeDeliveryId, isNull);
      expect(harness.viewModel.ridePhase, DriverRidePhase.idle);
    });

    test(
      'syncs realtime delivery already assigned in backend while locally offline',
      () async {
        final harness = _Harness.withDriver();
        harness.delivery.deliveries = [_delivery(status: 'ASSIGNED')];

        harness.viewModel.handleRealtimeDelivery(_event(restaurantName: ''));
        await _flushAsync();

        expect(harness.viewModel.isOnline, isTrue);
        expect(harness.viewModel.isOnRide, isTrue);
        expect(harness.viewModel.ridePhase, DriverRidePhase.toRestaurant);
        expect(harness.viewModel.pickupAddress, 'Resto, Kaloum, Conakry');
        expect(harness.viewModel.deliveryAddress, 'Rue client, Kipé, Ratoma');
        expect(
          harness.viewModel.consumePendingUiTransition(),
          DriverUiTransition.showRestaurantDialog,
        );
      },
    );

    test(
      'clears incoming delivery only when it has not been accepted',
      () async {
        final harness = _Harness.withDriver();
        harness.viewModel.isOnline = true;
        harness.viewModel.handleRealtimeDelivery(_event());
        await _flushAsync();

        harness.viewModel.clearIncomingIfNotAccepted();

        expect(harness.viewModel.activeDeliveryId, isNull);
        expect(harness.viewModel.currentDelivery, isNull);
        expect(harness.viewModel.ridePhase, DriverRidePhase.idle);
      },
    );

    test('resets the server session by setting the driver offline', () async {
      final harness = _Harness.withDriver();
      await harness.viewModel.goOnline();

      await harness.viewModel.resetDriverSessionServer();

      expect(
        harness.presence.updatedStatuses.last,
        DriverStatus.offline.apiValue,
      );
      expect(harness.viewModel.isOnline, isFalse);
      expect(harness.viewModel.isOnRide, isFalse);
      expect(harness.viewModel.error, isNull);
    });

    test('resets driver session locally', () async {
      final harness = _Harness.withDriver();
      harness.viewModel.isOnline = true;
      harness.viewModel.isOnRide = true;

      harness.viewModel.resetDriverSessionLocal();

      expect(harness.viewModel.isOnline, isFalse);
      expect(harness.viewModel.isOnRide, isFalse);
      expect(harness.viewModel.error, isNull);
      expect(harness.viewModel.activeDeliveryId, isNull);
      expect(harness.viewModel.currentDelivery, isNull);
      expect(harness.viewModel.ridePhase, DriverRidePhase.idle);
    });

    test('moveToCustomerStep returns error when no active delivery',
        () async {
      final harness = _Harness.withDriver();

      final result = await harness.viewModel.moveToCustomerStep();

      expect(
        result,
        'Impossible de confirmer la récupération de la commande.',
      );
    });

    test(
      'moveToCustomerStep handles OTP validation error',
      () async {
        final harness = _Harness.withDriver();
        harness.viewModel.isOnline = true;
        harness.viewModel.handleRealtimeDelivery(_event());
        await _flushAsync();
        await harness.viewModel.acceptIncomingRide();

        harness.delivery.shouldThrowOnUpdate = true;
        harness.delivery.updateErrorMessage =
            'Veuillez demander au restaurant de valider votre code de récupération.';

        final result = await harness.viewModel.moveToCustomerStep();

        expect(
          result,
          'Veuillez demander au restaurant de valider votre code de récupération.',
        );
      },
    );

    test(
      'moveToCustomerStep handles proximity error',
      () async {
        final harness = _Harness.withDriver();
        harness.viewModel.isOnline = true;
        harness.viewModel.handleRealtimeDelivery(_event());
        await _flushAsync();
        await harness.viewModel.acceptIncomingRide();

        harness.delivery.shouldThrowOnUpdate = true;
        harness.delivery.updateErrorMessage = 'proximité du restaurant';

        final result = await harness.viewModel.moveToCustomerStep();

        expect(
          result,
          'Vous devez être à proximité du restaurant pour récupérer cette commande.',
        );
      },
    );

    test(
      'moveToCustomerStep handles already picked up error',
      () async {
        final harness = _Harness.withDriver();
        harness.viewModel.isOnline = true;
        harness.viewModel.handleRealtimeDelivery(_event());
        await _flushAsync();
        await harness.viewModel.acceptIncomingRide();

        harness.delivery.shouldThrowOnUpdate = true;
        harness.delivery.updateErrorMessage = 'PICKED_UP to PICKED_UP';

        final result = await harness.viewModel.moveToCustomerStep();

        expect(result, isNull);
        expect(harness.viewModel.ridePhase, DriverRidePhase.toCustomer);
        expect(
          harness.viewModel.consumePendingUiTransition(),
          DriverUiTransition.showCustomerDialog,
        );
      },
    );

    test('restore sets pickupOtpCode from delivery', () async {
      final harness = _Harness.withDriver();
      harness.presence.status = DriverStatus.onDelivery;
      harness.delivery.deliveries = [{
        'id': 'delivery-1',
        'orderId': 'order-1',
        'driverId': 'driver-1',
        'status': 'ASSIGNED',
        'pickupOtpCode': '1234',
        'pickupAddress': {
          'address': 'Resto',
          'district': 'Kaloum',
          'commune': 'Conakry',
        },
        'deliveryAddress': {
          'address': 'Maison',
          'district': 'Kipé',
          'commune': 'Ratoma',
        },
        'fee': 15000,
        'distanceKm': 4.5,
        'driverAssignedAt': '2026-01-01T10:00:00Z',
        'createdAt': '2026-01-01T09:00:00Z',
      }];

      await harness.viewModel.restoreDriverSessionFromBackend();

      expect(harness.viewModel.pickupOtpCode, '1234');
    });

    test(
      'clearIncomingIfNotAccepted does nothing when already on ride',
      () async {
        final harness = _Harness.withDriver();
        harness.viewModel.isOnline = true;
        harness.viewModel.isOnRide = true;

        harness.viewModel.clearIncomingIfNotAccepted();

        expect(harness.viewModel.isOnRide, isTrue);
      },
    );

    test('goOffline returns error when on ride', () async {
      final harness = _Harness.withDriver();
      harness.viewModel.isOnline = true;
      harness.viewModel.isOnRide = true;

      await harness.viewModel.goOffline();

      expect(
        harness.viewModel.error,
        'Impossible de passer hors ligne pendant une course.',
      );
    });

    test('resetDriverSessionServer handles presence setStatus failure',
        () async {
      final harness = _Harness.withDriver();
      harness.presence.shouldThrowOnSetStatus = true;
      await harness.viewModel.goOnline();

      await harness.viewModel.resetDriverSessionServer();

      expect(harness.viewModel.isOnline, isFalse);
      expect(harness.viewModel.isOnRide, isFalse);
    });
  });
}

class _Harness {
  _Harness() {
    viewModel = DriverHomeViewModel(
      DriverPresenceRepository(service: presence),
      DriverDeliveryRepository(service: delivery),
      DriverOrderRepository(
        orderService: orders,
        orderDetailsRepository: OrderDetailsRepository(service: orderDetails),
      ),
      RestaurantRepository(service: restaurants, listService: restaurantList),
      currentUser,
      pickupPositionProvider: () async =>
          const PickupPosition(latitude: 9.6412, longitude: -13.5784),
    );
  }

  factory _Harness.withDriver() {
    final harness = _Harness();
    harness.currentUser.setUser(
      User(
        id: 'driver-1',
        firstName: 'Mamadou',
        lastName: 'Bah',
        phoneNumber: '620000000',
        role: 'DRIVER',
        isTemporaryPin: false,
      ),
    );
    return harness;
  }

  final presence = _FakeDriverPresenceService();
  final delivery = _FakeDriverDeliveryService();
  final orders = _FakeSharedOrderService();
  final orderDetails = _FakeOrderDetailsService();
  final restaurants = _FakeRestaurantService();
  final restaurantList = _FakeRestaurantListService();
  final currentUser = CurrentUserViewModel();
  late final DriverHomeViewModel viewModel;
}

class _FakeDriverPresenceService extends DriverPresenceService {
  DriverStatus status = DriverStatus.online;
  final updatedStatuses = <String>[];
  bool shouldThrowOnSetStatus = false;

  @override
  Future<Map<String, dynamic>> fetchDriverById({
    required String driverId,
  }) async {
    return {'driverId': driverId, 'status': status.apiValue};
  }

  @override
  Future<Map<String, dynamic>> updateDriverStatus({
    required String driverId,
    required String status,
  }) async {
    if (shouldThrowOnSetStatus) throw Exception('setStatus failed');
    updatedStatuses.add(status);
    this.status = DriverStatus.fromApi(status);
    return {'driverId': driverId, 'status': status};
  }
}

class _FakeDriverDeliveryService extends DriverDeliveryService {
  List<Map<String, dynamic>> deliveries = [];
  final assignedDriverIds = <String>[];
  final updatedStatuses = <String>[];
  bool shouldThrowOnUpdate = false;
  String updateErrorMessage = '';

  @override
  Future<Map<String, dynamic>> assignDriver({
    required String driverId,
    required String deliveryId,
  }) async {
    assignedDriverIds.add(driverId);
    return {
      'driverId': driverId,
      'deliveryId': deliveryId,
      'driverStatus': DriverStatus.onDelivery.apiValue,
      'deliveryStatus': DeliveryStatus.assigned.apiValue,
    };
  }

  @override
  Future<List<dynamic>> fetchDeliveriesByDriverId({
    required String driverId,
    List<String>? statuses,
  }) async {
    return deliveries;
  }

  @override
  Future<Map<String, dynamic>> updateDeliveryStatus({
    required String deliveryId,
    required String status,
    String? driverId,
    double? latitude,
    double? longitude,
  }) async {
    if (shouldThrowOnUpdate) throw Exception(updateErrorMessage);
    updatedStatuses.add(status);
    return {'deliveryId': deliveryId, 'status': status};
  }
}

class _FakeSharedOrderService extends SharedOrderService {
  @override
  Future<Map<String, dynamic>> fetchOrderById(
    dynamic orderId, {
    context,
  }) async {
    return _order(id: orderId.toString());
  }
}

class _FakeOrderDetailsService extends OrderDetailsService {
  @override
  Future<Map<String, dynamic>?> fetchOrderDetails(String orderId) async {
    return {
      'orderId': orderId,
      'driverDetails': {
        'id': 'driver-1',
        'firstName': 'Mamadou',
        'lastName': 'Bah',
        'phoneNumber': '620000000',
      },
      'customerDetails': {'phone': '621111111', 'name': 'Aminata Diallo'},
    };
  }
}

class _FakeRestaurantService extends RestaurantService {
  @override
  Future<Map<String, dynamic>> fetchRestaurant(String id) async {
    return {
      'id': id,
      'name': 'Restaurant API',
      'address': 'Kaloum',
      'phone': '620000000',
      'description': 'Cuisine locale',
      'imageUrl': 'https://example.com/restaurant.jpg',
      'menus': const [],
      'products': const [],
      'openingHours': const [],
    };
  }
}

class _FakeRestaurantListService extends RestaurantListService {}

Map<String, dynamic> _delivery({
  String id = 'delivery-1',
  String status = 'ASSIGNED',
  String assignedAt = '2026-01-01T10:00:00Z',
  String? pickedUpAt,
}) => {
  'id': id,
  'orderId': 'order-1',
  'driverId': 'driver-1',
  'status': status,
  'pickupAddress': {
    'address': 'Resto',
    'district': 'Kaloum',
    'commune': 'Conakry',
  },
  'deliveryAddress': {
    'address': 'Maison',
    'district': 'Kipé',
    'commune': 'Ratoma',
  },
  'fee': 15000,
  'distanceKm': 4.5,
  'driverAssignedAt': assignedAt,
  if (pickedUpAt != null) 'pickedUpAt': pickedUpAt,
  'createdAt': '2026-01-01T09:00:00Z',
};

Map<String, dynamic> _order({String id = 'order-1'}) => {
  'id': id,
  'shortId': 'A123',
  'name': 'Déjeuner',
  'restaurantId': 'restaurant-1',
  'restaurantName': 'Restaurant commande',
  'totalPrice': 35000,
  'serviceFee': 1000,
  'deliveryFee': 5000,
  'status': 'ACCEPTED',
  'createdDate': '2026-01-01T10:00:00Z',
  'lastModifiedDate': '2026-01-01T10:05:00Z',
  'customerId': 'customer-1',
  'deliveryContact': {
    'phoneNumber': '621111111',
    'address': 'Rue client',
    'district': 'Kipé',
    'commune': 'Ratoma',
    'firstName': 'Aminata',
    'lastName': 'Diallo',
  },
  'orderItems': const [],
};

DriverDeliveryEvent _event({String restaurantName = 'Restaurant socket'}) {
  return DriverDeliveryEvent(
    deliveryId: 'delivery-1',
    orderId: 'order-1',
    deliveryAddress: 'Adresse client socket',
    pickupAddress: 'Adresse resto socket',
    restaurantName: restaurantName,
    estimatedDeliveryDistance: 4.5,
    deliveryFee: 15000,
    driverIds: const ['driver-1'],
  );
}

Future<void> _flushAsync() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
