import 'package:dineroo_mobile/customer/models/domain/organization.dart';
import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:dineroo_mobile/manager/repositories/manager_order_repository.dart';
import 'package:dineroo_mobile/manager/services/manager_order_service.dart';
import 'package:dineroo_mobile/manager/view_models/home/manager_order_reception_view_model.dart';
import 'package:dineroo_mobile/manager/view_models/orders/manager_order_list_view_model.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_context_helper.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:dineroo_mobile/shared/views/orders/order_action_buttons/order_give_to_driver_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shows warning when no driver is assigned', (tester) async {
    await tester.pumpWidget(_buildTestApp(hasAssignedDriver: false));

    await tester.tap(find.text('Remettre au livreur'));
    await tester.pump();

    expect(
      find.text('Aucun livreur n\'est assigné à cette commande.'),
      findsOneWidget,
    );
  });

  testWidgets('shows error text when code is too short', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.tap(find.text('Remettre au livreur'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '12');
    await tester.tap(find.text('VALIDER'));
    await tester.pump();

    expect(find.text('Le code doit contenir 4 chiffres.'), findsOneWidget);
  });

  testWidgets('shows error text when invalid code entered', (tester) async {
    final service = _FakeManagerOrderService(returnNullOnValidate: true);
    await tester.pumpWidget(_buildTestApp(svc: service));

    await tester.tap(find.text('Remettre au livreur'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '1234');
    await tester.tap(find.text('VALIDER'));
    await tester.pumpAndSettle();

    expect(find.text('Le code saisi est invalide.'), findsOneWidget);
  });

  testWidgets('succeeds on valid code', (tester) async {
    final service = _FakeManagerOrderService();
    var actionCompleted = false;

    await tester.pumpWidget(
      _buildTestApp(
        svc: service,
        onActionComplete: () => actionCompleted = true,
      ),
    );

    await tester.tap(find.text('Remettre au livreur'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '1234');
    await tester.tap(find.text('VALIDER'));
    await tester.pumpAndSettle();

    expect(service.validatedOtpCode, '1234');
    expect(actionCompleted, isTrue);
  });

  testWidgets('clears error text when input changes', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.tap(find.text('Remettre au livreur'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '12');
    await tester.tap(find.text('VALIDER'));
    await tester.pump();
    expect(find.text('Le code doit contenir 4 chiffres.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '1234');
    await tester.pump();
    expect(find.text('Le code doit contenir 4 chiffres.'), findsNothing);
  });
}

Widget _buildTestApp({
  bool hasAssignedDriver = true,
  _FakeManagerOrderService? svc,
  VoidCallback? onActionComplete,
}) {
  final service = svc ?? _FakeManagerOrderService();
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
      ChangeNotifierProvider<CurrentUserViewModel>.value(value: currentUserVM),
      ChangeNotifierProvider<ManagerOrderReceptionViewModel>(
        create: (_) => ManagerOrderReceptionViewModel(
          repository: ManagerOrderRepository(service: service),
        ),
      ),
      ChangeNotifierProvider<ManagerOrderListViewModel>(
        create: (_) =>
            ManagerOrderListViewModel(ManagerOrderRepository(service: service)),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: OrderGiveToDriverButton(
          orderId: 'order-1',
          shortId: 'A123',
          hasAssignedDriver: hasAssignedDriver,
          onActionComplete: onActionComplete,
        ),
      ),
    ),
  );
}

class _FakeManagerOrderService extends ManagerOrderService {
  final bool returnNullOnValidate;
  String? validatedOtpCode;

  _FakeManagerOrderService({this.returnNullOnValidate = false});

  @override
  Future<List<Map<String, dynamic>>> fetchOrdersByRestaurant(
    String restaurantId, {
    required ApiContext context,
  }) async {
    return [];
  }

  @override
  Future<String> validatePickupOtp({
    required String orderId,
    required String code,
    String? validatedBy,
    required String restaurantId,
  }) async {
    validatedOtpCode = code;
    if (returnNullOnValidate) throw Exception('Code de récupération invalide.');
    return 'Code validé avec succès.';
  }

  @override
  Future<void> updateOrderStatus({
    required String restaurantId,
    required String orderId,
    required String status,
  }) async {}
}
