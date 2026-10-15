import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:dineroo_mobile/manager/repositories/manager_order_repository.dart';
import 'package:dineroo_mobile/manager/services/manager_order_service.dart';
import 'package:dineroo_mobile/manager/view_models/home/manager_order_reception_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:dineroo_mobile/shared/views/orders/order_action_buttons/order_accept_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shows error when restaurantId is null', (tester) async {
    final currentUserVM = CurrentUserViewModel()
      ..setUser(
        User(
          id: 'manager-1',
          firstName: 'Test',
          lastName: 'User',
          phoneNumber: '620000000',
          role: 'RESTAURANT_MANAGER',
          isTemporaryPin: false,
        ),
      );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentUserViewModel>.value(
            value: currentUserVM,
          ),
          ChangeNotifierProvider<ManagerOrderReceptionViewModel>(
            create: (_) => ManagerOrderReceptionViewModel(
              repository: ManagerOrderRepository(service: _FakeService()),
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: OrderAcceptButton(orderId: 'order-1')),
        ),
      ),
    );

    await tester.tap(find.text('ACCEPTER'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Restaurant introuvable'), findsOneWidget);
  });
}

class _FakeService extends ManagerOrderService {
  @override
  Future<List<Map<String, dynamic>>> fetchOrdersByRestaurant(
    String restaurantId, {
    required context,
  }) async {
    return [];
  }
}
