import 'dart:convert';

import 'package:dineroo_mobile/customer/models/domain/organization.dart';
import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:dineroo_mobile/manager/repositories/manager_order_repository.dart';
import 'package:dineroo_mobile/manager/repositories/manager_restaurant_repository.dart';
import 'package:dineroo_mobile/manager/services/manager_order_service.dart';
import 'package:dineroo_mobile/manager/services/manager_restaurant_service.dart';
import 'package:dineroo_mobile/manager/view_models/home/manager_order_reception_view_model.dart';
import 'package:dineroo_mobile/manager/view_models/orders/manager_order_list_view_model.dart';
import 'package:dineroo_mobile/manager/view_models/restaurant/manager_restaurant_view_model.dart';
import 'package:dineroo_mobile/manager/views/home/manager_home_view.dart';
import 'package:dineroo_mobile/manager/views/home/manager_suspension_banner.dart';
import 'package:dineroo_mobile/manager/views/orders/manager_orders_tab_ongoing.dart';
import 'package:dineroo_mobile/manager/views/restaurant/opening_hours/restaurant_opening_hours_view.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_context_helper.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  testWidgets('syncs and renders an empty manager dashboard', (tester) async {
    var reconnects = 0;
    var stops = 0;

    await tester.pumpWidget(
      _Harness(
        service: _FakeManagerOrderService(orders: const []),
        reconnectIfNeeded: () async => reconnects++,
        stopSound: () => stops++,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(reconnects, 1);
    expect(find.text('Chez Mariam'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
    expect(find.text('NOUVELLES COMMANDES'), findsOneWidget);
    expect(find.text('COMMANDES PRÊTES'), findsOneWidget);
    expect(find.text('Aucune commande pour le moment'), findsOneWidget);
    expect(stops, greaterThanOrEqualTo(1));
  });

  testWidgets('renders pending reception orders and counters', (tester) async {
    var plays = 0;
    final service = _FakeManagerOrderService(
      orders: [
        _orderJson(id: 'new-1', shortId: 'A123', status: 'PAYMENT_CONFIRMED'),
        _orderJson(id: 'ready-1', shortId: 'B456', status: 'READY_FOR_PICKUP'),
      ],
    );

    await tester.pumpWidget(
      _Harness(
        service: service,
        reconnectIfNeeded: () async {},
        playSoundLoop: () => plays++,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(service.restaurantIds, ['restaurant-1']);
    expect(find.text('1'), findsNWidgets(2));
    expect(find.text('NOUVEAU'), findsOneWidget);
    expect(find.text('Commande #A123'), findsOneWidget);
    expect(find.text('35 000 GNF'), findsWidgets);
    expect(find.text('Burger'), findsOneWidget);
    expect(find.text('Commande #B456'), findsNothing);
    expect(plays, 1);
  });

  testWidgets('renders reception orders horizontally in landscape', (
    tester,
  ) async {
    final service = _FakeManagerOrderService(
      orders: [
        _orderJson(id: 'new-1', shortId: 'A123', status: 'PAYMENT_CONFIRMED'),
        _orderJson(id: 'new-2', shortId: 'B456', status: 'PAYMENT_CONFIRMED'),
      ],
    );

    await tester.pumpWidget(
      _Harness(
        service: service,
        size: const Size(844, 390),
        reconnectIfNeeded: () async {},
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('horizontal-new-1-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('horizontal-new-2-1')), findsOneWidget);
    expect(find.text('NOUVELLES COMMANDES'), findsOneWidget);
    expect(find.text('COMMANDES PRÊTES'), findsOneWidget);
  });

  testWidgets('accepts from home card then order appears in preparation', (
    tester,
  ) async {
    final service = _FakeManagerOrderService(
      orders: [
        _orderJson(id: 'new-1', shortId: 'A123', status: 'PAYMENT_CONFIRMED'),
      ],
    );
    final harness = _Harness(service: service, reconnectIfNeeded: () async {});

    await tester.pumpWidget(harness);
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('ACCEPTER'));
    await tester.pump(const Duration(milliseconds: 600));

    expect(service.statusFor('new-1'), 'ACCEPTED');
    expect(harness.viewModel.orders, isEmpty);

    await _expectOrderInPreparationColumn(tester, service);
  });

  testWidgets('shows an error snackbar when accepting from home fails', (
    tester,
  ) async {
    final service = _FakeManagerOrderService(
      orders: [
        _orderJson(id: 'new-1', shortId: 'A123', status: 'PAYMENT_CONFIRMED'),
      ],
      acceptFails: true,
    );
    final harness = _Harness(service: service, reconnectIfNeeded: () async {});

    await tester.pumpWidget(harness);
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('ACCEPTER'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(service.statusFor('new-1'), 'PAYMENT_CONFIRMED');
    expect(harness.viewModel.orders, isNotEmpty);
    expect(find.text('Impossible d\'accepter la commande.'), findsOneWidget);
  });

  testWidgets(
    'accepts from home card detail then order appears in preparation',
    (tester) async {
      final service = _FakeManagerOrderService(
        orders: [
          _orderJson(id: 'new-1', shortId: 'A123', status: 'PAYMENT_CONFIRMED'),
        ],
      );
      final harness = _Harness(
        service: service,
        reconnectIfNeeded: () async {},
        orderDetailBuilder: (order) => _AcceptFromDetailView(orderId: order.id),
      );

      await tester.pumpWidget(harness);
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Commande #A123'));
      await tester.pumpAndSettle();
      expect(find.text('Détail test commande'), findsOneWidget);

      await tester.tap(find.text('ACCEPTER DEPUIS DETAIL'));
      await tester.pumpAndSettle();

      expect(service.statusFor('new-1'), 'ACCEPTED');
      expect(harness.viewModel.orders, isEmpty);

      await _expectOrderInPreparationColumn(tester, service);
    },
  );

  testWidgets('renders landscape layout with non-compact height >= 700', (
    tester,
  ) async {
    await tester.pumpWidget(
      _Harness(
        service: _FakeManagerOrderService(orders: const []),
        size: const Size(844, 800),
        reconnectIfNeeded: () async {},
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('NOUVELLES COMMANDES'), findsOneWidget);
    expect(find.text('COMMANDES PRÊTES'), findsOneWidget);
  });

  testWidgets('calls _openOpeningHoursEditor when Modifier is tapped', (
    tester,
  ) async {
    await tester.pumpWidget(
      _Harness(
        service: _FakeManagerOrderService(orders: const []),
        reconnectIfNeeded: () async {},
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Modifier'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(RestaurantOpeningHoursView), findsOneWidget);
  });

  testWidgets(
    'navigates to ready orders when Commandes prêtes card is tapped',
    (tester) async {
      int? openedTabIndex;

      await tester.pumpWidget(
        _Harness(
          service: _FakeManagerOrderService(orders: const []),
          reconnectIfNeeded: () async {},
          onOpenOrdersTab: (_, tabIndex) => openedTabIndex = tabIndex,
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('COMMANDES PRÊTES'));
      await tester.pump();
      await tester.pump();

      expect(openedTabIndex, 1);
    },
  );

  testWidgets('does not navigate when Nouvelles commandes card is tapped', (
    tester,
  ) async {
    int? openedTabIndex;

    await tester.pumpWidget(
      _Harness(
        service: _FakeManagerOrderService(orders: const []),
        reconnectIfNeeded: () async {},
        onOpenOrdersTab: (_, tabIndex) => openedTabIndex = tabIndex,
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('NOUVELLES COMMANDES'));
    await tester.pump();
    await tester.pump();

    expect(openedTabIndex, isNull);
  });

  testWidgets('shows the suspension banner when the restaurant is suspended', (
    tester,
  ) async {
    await tester.pumpWidget(
      _Harness(
        service: _FakeManagerOrderService(orders: const []),
        restaurantService: _FakeManagerRestaurantService(
          suspension: {
            'reason': 'EXCESSIVE_PREPARATION_TIME',
            'suspendedAt': '2026-08-18T10:15:30Z',
          },
        ),
        reconnectIfNeeded: () async {},
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(ManagerSuspensionBanner), findsOneWidget);
    expect(find.text('Restaurant suspendu'), findsOneWidget);
    expect(find.text('Délais de préparation excessifs'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  testWidgets('hides the suspension banner for an active restaurant', (
    tester,
  ) async {
    await tester.pumpWidget(
      _Harness(
        service: _FakeManagerOrderService(orders: const []),
        restaurantService: _FakeManagerRestaurantService(),
        reconnectIfNeeded: () async {},
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(ManagerSuspensionBanner), findsNothing);
    expect(find.text('Restaurant suspendu'), findsNothing);
    expect(find.text('Modifier'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
  });

  testWidgets('keeps order acceptance available while suspended', (
    tester,
  ) async {
    final service = _FakeManagerOrderService(
      orders: [
        _orderJson(id: 'new-1', shortId: 'A123', status: 'PAYMENT_CONFIRMED'),
      ],
    );

    await tester.pumpWidget(
      _Harness(
        service: service,
        restaurantService: _FakeManagerRestaurantService(
          suspension: {
            'reason': 'CONTRACT_BREACH',
            'suspendedAt': '2026-08-18T10:15:30Z',
          },
        ),
        reconnectIfNeeded: () async {},
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(ManagerSuspensionBanner), findsOneWidget);
    expect(_isEnabled(tester, 'ACCEPTER'), isTrue);
    expect(_isEnabled(tester, 'REFUSER'), isTrue);

    await tester.tap(find.text('ACCEPTER'));
    await tester.pump(const Duration(milliseconds: 600));

    expect(service.statusFor('new-1'), 'ACCEPTED');
  });

  testWidgets('handles lifecycle resumed event', (tester) async {
    var reconnects = 0;

    await tester.pumpWidget(
      _Harness(
        service: _FakeManagerOrderService(orders: const []),
        reconnectIfNeeded: () async => reconnects++,
      ),
    );
    await tester.pump();
    await tester.pump();

    final before = reconnects;

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();

    expect(reconnects, greaterThan(before));
  });
}

bool _isEnabled(WidgetTester tester, String label) {
  final button = tester.widget<ElevatedButton>(
    find.ancestor(
      of: find.text(label),
      matching: find.byType(ElevatedButton),
    ),
  );
  return button.onPressed != null;
}

Future<void> _expectOrderInPreparationColumn(
  WidgetTester tester,
  _FakeManagerOrderService service,
) async {
  final listVM = ManagerOrderListViewModel(
    ManagerOrderRepository(service: service),
  );

  await tester.pumpWidget(
    _OrdersColumnHarness(
      service: service,
      listVM: listVM,
      child: const ManagerOrdersTabOngoing(),
    ),
  );
  await listVM.fetchOrdersByRestaurant(
    tester.element(find.byType(ManagerOrdersTabOngoing)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));

  expect(find.textContaining('#A123'), findsOneWidget);
  expect(find.text('Marquer prête'), findsOneWidget);
}

class _FakeManagerRestaurantService extends ManagerRestaurantService {
  _FakeManagerRestaurantService({this.suspension});

  final Map<String, dynamic>? suspension;

  @override
  Future<Map<String, dynamic>> fetchRestaurant(
    String restaurantId, {
    required ApiContext context,
  }) async {
    return {
      'id': restaurantId,
      'name': 'Chez Mariam',
      'imageUrl': 'https://cdn.test/restaurant.png',
      'openingHours': const <Map<String, dynamic>>[],
      if (suspension != null) 'suspension': suspension,
    };
  }
}

class _Harness extends StatelessWidget {
  _Harness({
    required _FakeManagerOrderService service,
    ManagerRestaurantService? restaurantService,
    this.reconnectIfNeeded,
    this.playSoundLoop,
    this.stopSound,
    this.orderDetailBuilder,
    this.onOpenOrdersTab,
    this.size = const Size(390, 844),
  }) : viewModel = ManagerOrderReceptionViewModel(
         repository: ManagerOrderRepository(service: service),
       ),
       restaurantService = restaurantService ?? ManagerRestaurantService();

  final ManagerOrderReceptionViewModel viewModel;
  final ManagerRestaurantService restaurantService;
  final Future<void> Function()? reconnectIfNeeded;
  final VoidCallback? playSoundLoop;
  final VoidCallback? stopSound;
  final Widget Function(dynamic order)? orderDetailBuilder;
  final ManagerHomeOpenOrdersTab? onOpenOrdersTab;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final currentUserVM = CurrentUserViewModel()
      ..setUser(
        User(
          id: 'manager-1',
          firstName: 'Mariam',
          lastName: 'Diallo',
          phoneNumber: '620000000',
          role: 'RESTAURANT_MANAGER',
          isTemporaryPin: false,
          organization: Organization(id: 'restaurant-1', name: 'Chez Mariam'),
        ),
      );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CurrentUserViewModel>.value(
          value: currentUserVM,
        ),
        ChangeNotifierProvider<ManagerOrderReceptionViewModel>.value(
          value: viewModel,
        ),
        ChangeNotifierProvider<ManagerRestaurantViewModel>(
          create: (_) => ManagerRestaurantViewModel(
            ManagerRestaurantRepository(service: restaurantService),
            currentUserViewModel: currentUserVM,
          ),
        ),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: ManagerHomeView(
            reconnectIfNeeded: reconnectIfNeeded,
            playSoundLoop: playSoundLoop,
            stopSound: stopSound,
            orderDetailBuilder: orderDetailBuilder,
            onOpenOrdersTab: onOpenOrdersTab,
          ),
        ),
      ),
    );
  }
}

class _OrdersColumnHarness extends StatelessWidget {
  final _FakeManagerOrderService service;
  final ManagerOrderListViewModel listVM;
  final Widget child;

  const _OrdersColumnHarness({
    required this.service,
    required this.listVM,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserVM = _currentUserViewModel();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CurrentUserViewModel>.value(
          value: currentUserVM,
        ),
        ChangeNotifierProvider<ManagerOrderReceptionViewModel>(
          create: (_) => ManagerOrderReceptionViewModel(
            repository: ManagerOrderRepository(service: service),
          ),
        ),
        ChangeNotifierProvider<ManagerOrderListViewModel>.value(value: listVM),
      ],
      child: MaterialApp(
        home: Scaffold(body: SizedBox(width: 430, child: child)),
      ),
    );
  }
}

class _AcceptFromDetailView extends StatelessWidget {
  final dynamic orderId;

  const _AcceptFromDetailView({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail test commande')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final restaurantId = context
                .read<CurrentUserViewModel>()
                .currentUser
                ?.organization
                ?.id;
            if (restaurantId == null) return;

            final success = await context
                .read<ManagerOrderReceptionViewModel>()
                .acceptOrder(restaurantId, orderId.toString());
            if (context.mounted) Navigator.of(context).pop(success);
          },
          child: const Text('ACCEPTER DEPUIS DETAIL'),
        ),
      ),
    );
  }
}

CurrentUserViewModel _currentUserViewModel() {
  return CurrentUserViewModel()..setUser(
    User(
      id: 'manager-1',
      firstName: 'Mariam',
      lastName: 'Diallo',
      phoneNumber: '620000000',
      role: 'RESTAURANT_MANAGER',
      isTemporaryPin: false,
      organization: Organization(id: 'restaurant-1', name: 'Chez Mariam'),
    ),
  );
}

class _FakeManagerOrderService extends ManagerOrderService {
  _FakeManagerOrderService({required this.orders, this.acceptFails = false});

  final List<Map<String, dynamic>> orders;
  final bool acceptFails;
  final List<String> restaurantIds = [];

  String? statusFor(String orderId) {
    return orders
        .singleWhere((order) => order['id'] == orderId)['status']
        ?.toString();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchOrdersByRestaurant(
    String restaurantId, {
    required ApiContext context,
  }) async {
    restaurantIds.add(restaurantId);
    return (jsonDecode(jsonEncode(orders)) as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }

  @override
  Future<void> acceptOrder({
    required String restaurantId,
    required String orderId,
  }) async {
    if (acceptFails) {
      throw Exception('Accept failed');
    }

    final index = orders.indexWhere((order) => order['id'] == orderId);
    if (index != -1) {
      orders[index] = {...orders[index], 'status': 'ACCEPTED'};
    }
  }
}

Map<String, dynamic> _orderJson({
  required String id,
  required String shortId,
  required String status,
}) {
  return {
    'id': id,
    'shortId': shortId,
    'name': 'Commande #$shortId',
    'restaurantId': 'restaurant-1',
    'restaurantName': 'Chez Mariam',
    'totalPrice': 35000,
    'serviceFee': 1000,
    'deliveryFee': 4000,
    'status': status,
    'createdDate': '2026-01-03T09:00:00.000Z',
    'lastModifiedDate': '2026-01-03T09:10:00.000Z',
    'customerId': 'customer-1',
    'deliveryContact': {
      'firstName': 'Aminata',
      'lastName': 'Diallo',
      'phoneNumber': '620000000',
      'address': 'Rue 12',
      'district': 'Kipé',
      'commune': 'Ratoma',
    },
    'orderItems': [
      {
        'id': 1,
        'orderId': id,
        'name': 'Burger',
        'imageUrl': '',
        'quantity': 1,
        'price': 35000,
        'productId': 'product-1',
        'restaurantId': 'restaurant-1',
        'restaurantName': 'Chez Mariam',
      },
    ],
  };
}
