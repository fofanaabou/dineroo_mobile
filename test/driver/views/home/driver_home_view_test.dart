import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:dineroo_mobile/customer/repositories/restaurant_repository.dart';
import 'package:dineroo_mobile/customer/services/restaurant/restaurant_list_service.dart';
import 'package:dineroo_mobile/customer/services/restaurant/restaurant_service.dart';
import 'package:dineroo_mobile/driver/enums/driver_status.dart';
import 'package:dineroo_mobile/driver/repositories/driver_delivery_repository.dart';
import 'package:dineroo_mobile/driver/repositories/driver_order_repository.dart';
import 'package:dineroo_mobile/driver/repositories/driver_presence_repository.dart';
import 'package:dineroo_mobile/driver/services/delivery/driver_delivery_service.dart';
import 'package:dineroo_mobile/driver/services/driver_presence/driver_presence_service.dart';
import 'package:dineroo_mobile/driver/view_models/driver_home_view_model.dart';
import 'package:dineroo_mobile/driver/views/home/driver_home_view.dart';
import 'package:dineroo_mobile/shared/repositories/order_details_repository.dart';
import 'package:dineroo_mobile/shared/services/order/order_details_service.dart';
import 'package:dineroo_mobile/shared/services/order/shared_order_service.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('DriverHomeView', () {
    testWidgets('renders go online button when offline', (tester) async {
      final harness = _Harness.withDriver();
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DriverHomeViewModel>.value(
            value: harness.viewModel,
            child: DriverHomeView(
              wakelockSync: harness.trackWakelock,
              wakelockDisable: harness.trackWakelockDisable,
              mapViewBuilder: _sizedBoxMap,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Passer en ligne'), findsOneWidget);
      expect(find.text('Passer hors ligne'), findsNothing);
    });

    testWidgets('renders online controls when online and not on ride', (
      tester,
    ) async {
      final harness = _Harness.withDriver();
      await harness.viewModel.goOnline();
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DriverHomeViewModel>.value(
            value: harness.viewModel,
            child: DriverHomeView(
              wakelockSync: harness.trackWakelock,
              wakelockDisable: harness.trackWakelockDisable,
              mapViewBuilder: _sizedBoxMap,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Passer hors ligne'), findsOneWidget);
    });

    testWidgets('renders ride buttons when session has an active delivery', (
      tester,
    ) async {
      final harness = _Harness.withDriver();
      harness.presence.status = DriverStatus.onDelivery;
      harness.delivery.deliveries = [_deliveryJson(status: 'ASSIGNED')];
      await harness.viewModel.restoreDriverSessionFromBackend();
      harness.viewModel.consumePendingUiTransition();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DriverHomeViewModel>.value(
            value: harness.viewModel,
            child: DriverHomeView(
              wakelockSync: harness.trackWakelock,
              wakelockDisable: harness.trackWakelockDisable,
              mapViewBuilder: _sizedBoxMap,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Afficher la course'), findsOneWidget);
    });

    testWidgets('renders delivery button when heading to customer', (
      tester,
    ) async {
      final harness = _Harness.withDriver();
      harness.presence.status = DriverStatus.onDelivery;
      harness.delivery.deliveries = [_deliveryJson(status: 'PICKED_UP')];
      await harness.viewModel.restoreDriverSessionFromBackend();
      harness.viewModel.consumePendingUiTransition();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DriverHomeViewModel>.value(
            value: harness.viewModel,
            child: DriverHomeView(
              wakelockSync: harness.trackWakelock,
              wakelockDisable: harness.trackWakelockDisable,
              mapViewBuilder: _sizedBoxMap,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Afficher la livraison'), findsOneWidget);
    });

    testWidgets('shows snackbar error when going online fails', (
      tester,
    ) async {
      final harness = _Harness.withDriver();
      harness.presence.shouldThrowOnUpdate = true;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DriverHomeViewModel>.value(
            value: harness.viewModel,
            child: DriverHomeView(
              wakelockSync: harness.trackWakelock,
              wakelockDisable: harness.trackWakelockDisable,
              mapViewBuilder: _sizedBoxMap,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Passer en ligne'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Impossible de passer en ligne.'), findsOneWidget);
    });

    testWidgets('shows snackbar error when going offline fails', (
      tester,
    ) async {
      final harness = _Harness.withDriver();
      await harness.viewModel.goOnline();
      harness.presence.shouldThrowOnUpdate = true;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DriverHomeViewModel>.value(
            value: harness.viewModel,
            child: DriverHomeView(
              wakelockSync: harness.trackWakelock,
              wakelockDisable: harness.trackWakelockDisable,
              mapViewBuilder: _sizedBoxMap,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Passer hors ligne'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Impossible de passer hors ligne.'), findsOneWidget);
    });

    testWidgets('opens restaurant dialog when tapping display trip button', (
      tester,
    ) async {
      final harness = _Harness.withDriver();
      harness.presence.status = DriverStatus.onDelivery;
      harness.delivery.deliveries = [_deliveryJson(status: 'ASSIGNED')];
      await harness.viewModel.restoreDriverSessionFromBackend();
      harness.viewModel.consumePendingUiTransition();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DriverHomeViewModel>.value(
            value: harness.viewModel,
            child: DriverHomeView(
              wakelockSync: harness.trackWakelock,
              wakelockDisable: harness.trackWakelockDisable,
              mapViewBuilder: _sizedBoxMap,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('Afficher la course'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text("J'ai récupéré la commande"), findsOneWidget);
    });

    testWidgets('opens customer dialog when tapping delivery button', (
      tester,
    ) async {
      final harness = _Harness.withDriver();
      harness.presence.status = DriverStatus.onDelivery;
      harness.delivery.deliveries = [_deliveryJson(status: 'PICKED_UP')];
      await harness.viewModel.restoreDriverSessionFromBackend();
      harness.viewModel.consumePendingUiTransition();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DriverHomeViewModel>.value(
            value: harness.viewModel,
            child: DriverHomeView(
              wakelockSync: harness.trackWakelock,
              wakelockDisable: harness.trackWakelockDisable,
              mapViewBuilder: _sizedBoxMap,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('Afficher la livraison'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Client'), findsOneWidget);
    });
  });
}

Widget _sizedBoxMap(BuildContext _) =>
    const SizedBox(key: Key('map-placeholder'));

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
  final wakelockStates = <bool>[];
  final wakelockDisableCalls = <int>[];

  Future<void> trackWakelock(bool state) async {
    wakelockStates.add(state);
  }

  Future<void> trackWakelockDisable() async {
    wakelockDisableCalls.add(wakelockDisableCalls.length + 1);
  }
}

class _FakeDriverPresenceService extends DriverPresenceService {
  DriverStatus status = DriverStatus.online;
  bool shouldThrowOnUpdate = false;

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
    if (shouldThrowOnUpdate) throw Exception('Failed');
    this.status = DriverStatus.fromApi(status);
    return {'driverId': driverId, 'status': status};
  }
}

class _FakeDriverDeliveryService extends DriverDeliveryService {
  List<Map<String, dynamic>> deliveries = [];

  @override
  Future<Map<String, dynamic>> assignDriver({
    required String driverId,
    required String deliveryId,
  }) async {
    return {
      'driverId': driverId,
      'deliveryId': deliveryId,
      'driverStatus': 'ON_DELIVERY',
      'deliveryStatus': 'ASSIGNED',
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
    return {'deliveryId': deliveryId, 'status': status};
  }
}

class _FakeSharedOrderService extends SharedOrderService {
  @override
  Future<Map<String, dynamic>> fetchOrderById(
    dynamic orderId, {
    context,
  }) async {
    return _orderJson(id: orderId.toString());
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
      'name': 'Restaurant Test',
      'address': 'Kaloum',
      'phone': '620000000',
      'description': 'Cuisine locale',
      'imageUrl': 'https://example.com/test.jpg',
      'menus': const [],
      'products': const [],
      'openingHours': const [],
    };
  }
}

class _FakeRestaurantListService extends RestaurantListService {}

Map<String, dynamic> _deliveryJson({
  String id = 'delivery-1',
  String status = 'ASSIGNED',
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
  'driverAssignedAt': '2026-01-01T10:00:00Z',
  'createdAt': '2026-01-01T09:00:00Z',
};

Map<String, dynamic> _orderJson({String id = 'order-1'}) => {
  'id': id,
  'shortId': 'A123',
  'name': 'Course',
  'restaurantId': 'restaurant-1',
  'restaurantName': 'Restaurant Test',
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
