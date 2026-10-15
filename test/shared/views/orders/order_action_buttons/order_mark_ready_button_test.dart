import 'package:dineroo_mobile/customer/models/domain/organization.dart';
import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:dineroo_mobile/manager/repositories/manager_order_repository.dart';
import 'package:dineroo_mobile/manager/services/manager_order_service.dart';
import 'package:dineroo_mobile/manager/view_models/home/manager_order_reception_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:dineroo_mobile/shared/views/orders/order_action_buttons/order_mark_ready_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  late _FakeManagerOrderService service;

  setUp(() {
    service = _FakeManagerOrderService();
  });

  Widget buildTestApp({
    required String orderId,
    required bool enabled,
    _FakeManagerOrderService? svc,
    bool withOrg = true,
  }) {
    final currentUserVM = CurrentUserViewModel();
    if (withOrg) {
      currentUserVM.setUser(
        User(
          id: 'manager-1',
          firstName: 'Test',
          lastName: 'User',
          phoneNumber: '620000000',
          role: 'RESTAURANT_MANAGER',
          isTemporaryPin: false,
          organization: Organization(id: 'restaurant-1', name: 'Test'),
        ),
      );
    } else {
      currentUserVM.setUser(
        User(
          id: 'manager-1',
          firstName: 'Test',
          lastName: 'User',
          phoneNumber: '620000000',
          role: 'RESTAURANT_MANAGER',
          isTemporaryPin: false,
        ),
      );
    }
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CurrentUserViewModel>.value(
          value: currentUserVM,
        ),
        ChangeNotifierProvider<ManagerOrderReceptionViewModel>(
          create: (_) => ManagerOrderReceptionViewModel(
            repository: ManagerOrderRepository(service: svc ?? service),
          ),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: OrderMarkReadyButton(orderId: orderId, enabled: enabled),
        ),
      ),
    );
  }

  testWidgets('marks order as ready on success', (tester) async {
    await tester.pumpWidget(buildTestApp(orderId: 'order-1', enabled: true));
    await tester.tap(find.text('Marquer prête'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(service.updatedStatus, 'READY');
    expect(find.text('Commande marquée comme prête'), findsOneWidget);
  });

  testWidgets('shows error when restaurantId is null', (tester) async {
    await tester.pumpWidget(
      buildTestApp(orderId: 'order-1', enabled: true, withOrg: false),
    );
    await tester.tap(find.text('Marquer prête'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Restaurant introuvable'), findsOneWidget);
  });

  testWidgets('shows error when update fails', (tester) async {
    service.shouldFail = true;

    await tester.pumpWidget(buildTestApp(orderId: 'order-1', enabled: true));
    await tester.tap(find.text('Marquer prête'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Échec lors de la mise à jour'), findsOneWidget);
  });
}

class _FakeManagerOrderService extends ManagerOrderService {
  String? updatedStatus;
  bool shouldFail = false;

  @override
  Future<void> updateOrderStatus({
    required String restaurantId,
    required String orderId,
    required String status,
  }) async {
    if (shouldFail) throw Exception('Update failed');
    updatedStatus = status;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchOrdersByRestaurant(
    String restaurantId, {
    required context,
  }) async {
    return [];
  }
}
