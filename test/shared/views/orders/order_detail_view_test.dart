import 'package:dineroo_mobile/customer/models/domain/organization.dart';
import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:dineroo_mobile/manager/enums/order_source.dart';
import 'package:dineroo_mobile/manager/repositories/manager_order_repository.dart';
import 'package:dineroo_mobile/manager/services/manager_order_service.dart';
import 'package:dineroo_mobile/manager/view_models/home/manager_order_reception_view_model.dart';
import 'package:dineroo_mobile/manager/view_models/orders/manager_order_list_view_model.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_context_helper.dart';
import 'package:dineroo_mobile/shared/enums/order_status.dart';
import 'package:dineroo_mobile/shared/repositories/order_details_repository.dart';
import 'package:dineroo_mobile/shared/services/order/order_details_service.dart';
import 'package:dineroo_mobile/shared/services/order/shared_order_service.dart';
import 'package:dineroo_mobile/shared/view_models/order/order_detail_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:dineroo_mobile/shared/views/orders/order_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  group('OrderDetailView', () {
    testWidgets('renders customer order details from injected view model', (
      tester,
    ) async {
      final viewModel = _viewModel();
      await viewModel.init('order-1');

      await tester.pumpWidget(
        MaterialApp(
          home: OrderDetailView(orderId: 'order-1', viewModel: viewModel),
        ),
      );
      await tester.pump();

      expect(find.text('Détail de la commande'), findsOneWidget);
      expect(find.text('Acceptée'), findsOneWidget);
      expect(find.text('Chez Mariam'), findsOneWidget);
      expect(find.text('Contenu de la commande'), findsOneWidget);
      expect(find.text('Burger'), findsOneWidget);
      expect(find.text('Sous-total produits'), findsOneWidget);
      expect(find.text('Frais de livraison'), findsOneWidget);
      expect(find.text('Frais de service'), findsOneWidget);
      expect(find.text('Total payé'), findsOneWidget);
      expect(find.text('Réduction'), findsNothing);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.data?.replaceAll(RegExp(r'\s'), ' ') == '36 000 GNF',
        ),
        findsOneWidget,
      );
      expect(find.text('Commentaire'), findsOneWidget);
      expect(find.text('Sans oignon'), findsOneWidget);
      expect(find.text('Informations de livraison'), findsOneWidget);
      expect(find.text('Rue 12, Kipé, Ratoma'), findsOneWidget);
      expect(find.text('Livreur assigné'), findsOneWidget);
      expect(find.text('Acceptée le 03 JANV. 2026, 10:13'), findsOneWidget);

      await tester.drag(find.byType(Scrollable), const Offset(0, -300));
      await tester.pump();

      expect(find.text('Mamadou'), findsOneWidget);
    });

    testWidgets('shows retry state when injected view model has an error', (
      tester,
    ) async {
      final viewModel = _viewModel(orderError: Exception('backend down'));
      await viewModel.init('order-1');

      await tester.pumpWidget(
        MaterialApp(
          home: OrderDetailView(orderId: 'order-1', viewModel: viewModel),
        ),
      );
      await tester.pump();

      expect(find.text('Détail de la commande'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('accept action works from manager order detail', (tester) async {
      final service = _FakeManagerOrderService();
      final viewModel = _viewModel(status: 'PAYMENT_CONFIRMED');
      await viewModel.init('order-1');

      await tester.pumpWidget(
        _ManagerDetailTestApp(
          service: service,
          child: OrderDetailView(
            orderId: 'order-1',
            source: OrderSource.reception,
            viewModel: viewModel,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ACCEPTER'));
      await tester.pumpAndSettle();

      expect(service.acceptedOrderId, 'order-1');
    });

    testWidgets('reject action works from manager order detail', (tester) async {
      final service = _FakeManagerOrderService();
      final viewModel = _viewModel(status: 'PAYMENT_CONFIRMED');
      await viewModel.init('order-1');

      await tester.pumpWidget(
        _ManagerDetailTestApp(
          service: service,
          child: OrderDetailView(
            orderId: 'order-1',
            source: OrderSource.reception,
            viewModel: viewModel,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('REFUSER'));
      await tester.pumpAndSettle();
      expect(find.text('OUI, REFUSER'), findsOneWidget);

      await tester.tap(find.text('OUI, REFUSER'));
      await tester.pumpAndSettle();

      expect(service.rejectedOrderId, 'order-1');
    });

    testWidgets('mark ready action works from manager order detail', (
      tester,
    ) async {
      final service = _FakeManagerOrderService();
      final listVM = ManagerOrderListViewModel(
        ManagerOrderRepository(service: service),
      );
      final viewModel = _viewModel(status: 'ACCEPTED');
      await viewModel.init('order-1');

      await tester.pumpWidget(
        _ManagerDetailTestApp(
          service: service,
          listVM: listVM,
          child: OrderDetailView(
            orderId: 'order-1',
            source: OrderSource.ongoing,
            viewModel: viewModel,
          ),
        ),
      );
      await listVM.fetchOrdersByRestaurant(
        tester.element(find.byType(OrderDetailView)),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Marquer prête'));
      await tester.tap(find.text('Marquer prête'));
      await tester.pumpAndSettle();

      expect(service.updatedStatus, 'READY');
      expect(
        listVM.orders.singleWhere((order) => order.id == 'order-1').status,
        OrderStatus.readyForPickup,
      );
    });

    testWidgets('give to driver action works from manager order detail after OTP', (
      tester,
    ) async {
      final service = _FakeManagerOrderService();
      final listVM = ManagerOrderListViewModel(
        ManagerOrderRepository(service: service),
      );
      final viewModel = _viewModel(status: 'READY_FOR_PICKUP');
      await viewModel.init('order-1');

      await tester.pumpWidget(
        _ManagerDetailTestApp(
          service: service,
          listVM: listVM,
          child: OrderDetailView(
            orderId: 'order-1',
            source: OrderSource.ready,
            viewModel: viewModel,
          ),
        ),
      );
      await listVM.fetchOrdersByRestaurant(
        tester.element(find.byType(OrderDetailView)),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Remettre au livreur'));
      await tester.tap(find.text('Remettre au livreur'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '9879');
      await tester.tap(find.text('VALIDER'));
      await tester.pumpAndSettle();

      expect(service.validatedPickupOtpCode, '9879');
      expect(
        listVM.orders.singleWhere((order) => order.id == 'order-1').status,
        OrderStatus.pickedUp,
      );
    });
  });
}

OrderDetailViewModel _viewModel({
  Object? orderError,
  String status = 'ACCEPTED',
}) {
  return OrderDetailViewModel(
    sharedOrderService: _FakeSharedOrderService(
      error: orderError,
      status: status,
    ),
    orderDetailsRepository: OrderDetailsRepository(
      service: _FakeOrderDetailsService(),
    ),
  );
}

class _ManagerDetailTestApp extends StatelessWidget {
  final Widget child;
  final _FakeManagerOrderService service;
  final ManagerOrderListViewModel? listVM;

  const _ManagerDetailTestApp({
    required this.child,
    required this.service,
    this.listVM,
  });

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
        ChangeNotifierProvider<ManagerOrderReceptionViewModel>(
          create: (_) => ManagerOrderReceptionViewModel(
            repository: ManagerOrderRepository(service: service),
          ),
        ),
        ChangeNotifierProvider<ManagerOrderListViewModel>.value(
          value:
              listVM ??
              ManagerOrderListViewModel(
                ManagerOrderRepository(service: service),
              ),
        ),
      ],
      child: MaterialApp(home: child),
    );
  }
}

class _FakeManagerOrderService extends ManagerOrderService {
  String? acceptedOrderId;
  String? rejectedOrderId;
  String? updatedStatus;
  String? validatedPickupOtpCode;

  @override
  Future<List<Map<String, dynamic>>> fetchOrdersByRestaurant(
    String restaurantId, {
    required ApiContext context,
  }) async {
    return [_orderJson('order-1', 'ACCEPTED')];
  }

  @override
  Future<void> acceptOrder({
    required String restaurantId,
    required String orderId,
  }) async {
    acceptedOrderId = orderId;
  }

  @override
  Future<void> rejectOrder({
    required String restaurantId,
    required String orderId,
  }) async {
    rejectedOrderId = orderId;
  }

  @override
  Future<void> updateOrderStatus({
    required String restaurantId,
    required String orderId,
    required String status,
  }) async {
    updatedStatus = status;
  }

  @override
  Future<String> validatePickupOtp({
    required String orderId,
    required String code,
    String? validatedBy,
    required String restaurantId,
  }) async {
    validatedPickupOtpCode = code;
    return 'Code validé avec succès.';
  }
}

class _FakeSharedOrderService extends SharedOrderService {
  final Object? error;
  final String status;

  _FakeSharedOrderService({this.error, required this.status});

  @override
  Future<Map<String, dynamic>> fetchOrderById(
    dynamic orderId, {
    context,
  }) async {
    final error = this.error;
    if (error != null) throw error;

    return _orderJson(orderId.toString(), status);
  }
}

Map<String, dynamic> _orderJson(String orderId, String status) {
  return {
    'id': orderId,
    'shortId': 'A123',
    'restaurantId': 'restaurant-1',
    'restaurantName': 'Chez Mariam',
    'totalPrice': 35000,
    'serviceFee': 1000,
    'deliveryFee': 5000,
    'status': status,
    'createdDate': '2026-01-03T09:05:00.000Z',
    'lastModifiedDate': '2026-01-03T09:10:00.000Z',
    'statusDate': '2026-01-03T10:13:00.000Z',
    'comment': 'Sans oignon',
    'customerId': 'customer-1',
    'deliveryContact': {
      'firstName': 'Aminata',
      'lastName': 'Diallo',
      'phoneNumber': '620000000',
      'address': 'Rue 12',
      'district': 'Kipé',
      'commune': 'Ratoma',
    },
    'items': [_orderItemJson(orderId)],
    'orderItems': [_orderItemJson(orderId)],
  };
}

Map<String, dynamic> _orderItemJson(String orderId) {
  return {
    'id': 1,
    'orderId': orderId,
    'productId': 'product-1',
    'menuId': null,
    'imageUrl': '',
    'quantity': 1,
    'price': 30000,
    'name': 'Burger',
    'restaurantId': 'restaurant-1',
    'restaurantName': 'Chez Mariam',
  };
}

class _FakeOrderDetailsService extends OrderDetailsService {
  @override
  Future<Map<String, dynamic>> fetchOrderDetails(String orderId) async {
    return {
      'orderId': orderId,
      'driverDetails': {
        'id': 'driver-1',
        'firstName': 'Mamadou',
        'lastName': 'Bah',
        'phoneNumber': '',
      },
      'customerDetails': {'phone': '620000000', 'name': 'Aminata Diallo'},
    };
  }
}
