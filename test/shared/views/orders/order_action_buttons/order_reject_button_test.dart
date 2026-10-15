import 'package:dineroo_mobile/customer/models/domain/organization.dart';
import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:dineroo_mobile/manager/repositories/manager_order_repository.dart';
import 'package:dineroo_mobile/manager/services/manager_order_service.dart';
import 'package:dineroo_mobile/manager/view_models/home/manager_order_reception_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:dineroo_mobile/shared/views/orders/order_action_buttons/order_reject_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  late _FakeManagerOrderService service;

  setUp(() {
    service = _FakeManagerOrderService();
  });

  Widget buildTestApp({_FakeManagerOrderService? svc}) {
    final currentUserVM = CurrentUserViewModel()
      ..setUser(
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
        home: Scaffold(body: OrderRejectButton(orderId: 'order-1')),
      ),
    );
  }

  testWidgets('shows error when reject fails', (tester) async {
    service.shouldFail = true;

    await tester.pumpWidget(buildTestApp(svc: service));
    await tester.tap(find.text('REFUSER'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('OUI, REFUSER'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Erreur lors du refus de la commande'), findsOneWidget);
  });
}

class _FakeManagerOrderService extends ManagerOrderService {
  bool shouldFail = false;

  @override
  Future<void> rejectOrder({
    required String restaurantId,
    required String orderId,
  }) async {
    if (shouldFail) throw Exception('Reject failed');
  }

  @override
  Future<List<Map<String, dynamic>>> fetchOrdersByRestaurant(
    String restaurantId, {
    required context,
  }) async {
    return [];
  }
}
