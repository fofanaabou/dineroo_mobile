import 'dart:io';

import 'package:dineroo_mobile/customer/enums/checkout_payment_method.dart';
import 'package:dineroo_mobile/customer/enums/payment_gateway_result.dart';
import 'package:dineroo_mobile/customer/enums/payment_status.dart';
import 'package:dineroo_mobile/customer/exceptions/order_creation_exception.dart';
import 'package:dineroo_mobile/customer/models/domain/cart_group.dart';
import 'package:dineroo_mobile/customer/models/domain/cart_item.dart';
import 'package:dineroo_mobile/customer/models/domain/delivery_address.dart';
import 'package:dineroo_mobile/customer/models/domain/payment.dart';
import 'package:dineroo_mobile/customer/models/domain/product.dart';
import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:dineroo_mobile/customer/repositories/payment_repository.dart';
import 'package:dineroo_mobile/customer/repositories/wallet_repository.dart';
import 'package:dineroo_mobile/customer/services/payment/payment_service.dart';
import 'package:dineroo_mobile/customer/services/wallet/wallet_service.dart';
import 'package:dineroo_mobile/customer/view_models/cart/cart_view_model.dart';
import 'package:dineroo_mobile/customer/view_models/payment/payment_view_model.dart';
import 'package:dineroo_mobile/customer/view_models/wallet/wallet_view_model.dart';
import 'package:dineroo_mobile/customer/views/cart/cart_payment_button.dart';
import 'package:dineroo_mobile/shared/enums/order_status.dart';
import 'package:dineroo_mobile/shared/models/domain/order.dart';
import 'package:dineroo_mobile/shared/models/domain/order_delivery_contact.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

void main() {
  late Directory hiveDir;

  setUpAll(() async {
    hiveDir = await Directory.systemTemp.createTemp(
      'cart_payment_button_test_',
    );
    Hive.init(hiveDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DeliveryAddressAdapter());
    }
    await Hive.openBox<DeliveryAddress>('deliveryAddressBox');
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDir.delete(recursive: true);
  });

  testWidgets('is disabled while estimation is missing', (tester) async {
    final cartVM = _FakeCartViewModel(hasEstimation: false);

    await tester.pumpWidget(_Harness(cartVM: cartVM));

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('shows an error when restaurant is closed', (tester) async {
    final cartVM = _FakeCartViewModel();

    await tester.pumpWidget(
      _Harness(
        cartVM: cartVM,
        button: CartPaymentButton(
          group: _group,
          restaurantOpenChecker: (_, __) async => false,
          openDeliveryForm: (_, __, ___) async => true,
        ),
      ),
    );

    await tester.tap(find.text('Payer'));
    await tester.pump();

    expect(find.text('Ce restaurant est actuellement fermé.'), findsOneWidget);
  });

  testWidgets('does not claim closed when the open check fails', (
    tester,
  ) async {
    final cartVM = _FakeCartViewModel();
    var orderCreated = false;

    await tester.pumpWidget(
      _Harness(
        cartVM: cartVM,
        button: CartPaymentButton(
          group: _group,
          restaurantOpenChecker: (_, __) async => throw Exception('offline'),
          openDeliveryForm: (_, __, ___) async => true,
          createOrder: (_, __, ___, ____) async {
            orderCreated = true;
            return _order;
          },
        ),
      ),
    );

    await tester.tap(find.text('Payer'));
    await tester.pump();

    expect(
      find.text(
        'Impossible de vérifier les horaires du restaurant. Veuillez réessayer.',
      ),
      findsOneWidget,
    );
    expect(find.text('Ce restaurant est actuellement fermé.'), findsNothing);
    expect(orderCreated, isFalse);
  });

  testWidgets('shows an error when current user is missing', (tester) async {
    final cartVM = _FakeCartViewModel();

    await tester.pumpWidget(
      _Harness(
        cartVM: cartVM,
        includeCurrentUser: false,
        button: CartPaymentButton(
          group: _group,
          restaurantOpenChecker: (_, __) async => true,
          openDeliveryForm: (_, __, ___) async => true,
        ),
      ),
    );

    await tester.tap(find.text('Payer'));
    await tester.pump();

    expect(find.text('Utilisateur non connecté.'), findsOneWidget);
  });

  testWidgets('validates required delivery fields before checkout', (
    tester,
  ) async {
    final cartVM = _FakeCartViewModel(
      address: 'Rue 12',
      firstName: null,
      phoneNumber: null,
      district: null,
    );

    await tester.pumpWidget(
      _Harness(
        cartVM: cartVM,
        button: CartPaymentButton(
          group: _group,
          restaurantOpenChecker: (_, __) async => true,
          openDeliveryForm: (_, __, ___) async => true,
        ),
      ),
    );

    await tester.tap(find.text('Payer'));
    await tester.pump();

    expect(
      find.text('Veuillez renseigner le prénom, le téléphone et le quartier.'),
      findsOneWidget,
    );
  });

  testWidgets('confirms a successful gateway payment', (tester) async {
    final cartVM = _FakeCartViewModel();
    Order? confirmedOrder;

    await tester.pumpWidget(
      _Harness(
        cartVM: cartVM,
        button: CartPaymentButton(
          group: _group,
          restaurantOpenChecker: (_, __) async => true,
          openDeliveryForm: (_, __, ___) async => true,
          createOrder: (_, __, ___, ____) async => _order,
          createPayment: (_, __, ___, ____, _____) async => _payment,
          openPaymentGateway: (_, __) async => PaymentGatewayResult.success,
          waitForPaymentStatus: (_, __, ___) async => PaymentStatus.success,
          onPaymentConfirmed: (_, __, cart, order) {
            cart.removeCartGroup('restaurant-1');
            confirmedOrder = order;
          },
        ),
      ),
    );

    await tester.tap(find.text('Payer'));
    await _confirmPaymentMethod(tester, CheckoutPaymentMethod.djomy);

    expect(confirmedOrder?.id, 'order-1');
    expect(cartVM.consumedDeliveryConfirmation, isTrue);
    expect(cartVM.removedRestaurantIds, ['restaurant-1']);
  });

  testWidgets('shows failed and canceled payment messages', (tester) async {
    final cartVM = _FakeCartViewModel();

    await tester.pumpWidget(
      _Harness(
        cartVM: cartVM,
        button: CartPaymentButton(
          group: _group,
          restaurantOpenChecker: (_, __) async => true,
          openDeliveryForm: (_, __, ___) async => true,
          createOrder: (_, __, ___, ____) async => _order,
          createPayment: (_, __, ___, ____, _____) async => _payment,
          openPaymentGateway: (_, __) async => PaymentGatewayResult.failed,
        ),
      ),
    );

    await tester.tap(find.text('Payer'));
    await _confirmPaymentMethod(tester, CheckoutPaymentMethod.djomy);

    expect(find.text('Paiement refusé. Veuillez réessayer.'), findsOneWidget);
  });

  testWidgets('refreshes once when gateway has no final status', (
    tester,
  ) async {
    final cartVM = _FakeCartViewModel();
    var refreshedPaymentId = '';

    await tester.pumpWidget(
      _Harness(
        cartVM: cartVM,
        button: CartPaymentButton(
          group: _group,
          restaurantOpenChecker: (_, __) async => true,
          openDeliveryForm: (_, __, ___) async => true,
          createOrder: (_, __, ___, ____) async => _order,
          createPayment: (_, __, ___, ____, _____) async => _payment,
          openPaymentGateway: (_, __) async => PaymentGatewayResult.noStatus,
          refreshPaymentStatus: (_, paymentId) async {
            refreshedPaymentId = paymentId;
            return PaymentStatus.unknown;
          },
        ),
      ),
    );

    await tester.tap(find.text('Payer'));
    await _confirmPaymentMethod(tester, CheckoutPaymentMethod.djomy);

    expect(refreshedPaymentId, 'payment-1');
    expect(
      find.text('Paiement interrompu. Veuillez réessayer.'),
      findsOneWidget,
    );
  });

  testWidgets('uses default refresh once when gateway has no final status', (
    tester,
  ) async {
    final cartVM = _FakeCartViewModel();
    final paymentVM = _FakePaymentViewModel([PaymentStatus.success]);
    Order? confirmedOrder;

    await tester.pumpWidget(
      _Harness(
        cartVM: cartVM,
        paymentVM: paymentVM,
        button: CartPaymentButton(
          group: _group,
          restaurantOpenChecker: (_, __) async => true,
          openDeliveryForm: (_, __, ___) async => true,
          createOrder: (_, __, ___, ____) async => _order,
          createPayment: (_, __, ___, ____, _____) async => _payment,
          openPaymentGateway: (_, __) async => PaymentGatewayResult.noStatus,
          onPaymentConfirmed: (_, __, ___, order) => confirmedOrder = order,
        ),
      ),
    );

    await tester.tap(find.text('Payer'));
    await _confirmPaymentMethod(tester, CheckoutPaymentMethod.djomy);

    expect(paymentVM.refreshedIds, ['payment-1']);
    expect(confirmedOrder?.id, 'order-1');
  });

  testWidgets('uses default backend confirmation after gateway success', (
    tester,
  ) async {
    final cartVM = _FakeCartViewModel();
    final paymentVM = _FakePaymentViewModel([PaymentStatus.success]);
    Order? confirmedOrder;

    await tester.pumpWidget(
      _Harness(
        cartVM: cartVM,
        paymentVM: paymentVM,
        button: CartPaymentButton(
          group: _group,
          restaurantOpenChecker: (_, __) async => true,
          openDeliveryForm: (_, __, ___) async => true,
          createOrder: (_, __, ___, ____) async => _order,
          createPayment: (_, __, ___, ____, _____) async => _payment,
          openPaymentGateway: (_, __) async => PaymentGatewayResult.success,
          onPaymentConfirmed: (_, __, ___, order) => confirmedOrder = order,
        ),
      ),
    );

    await tester.tap(find.text('Payer'));
    await _confirmPaymentMethod(tester, CheckoutPaymentMethod.djomy);

    expect(paymentVM.refreshedIds, ['payment-1']);
    expect(confirmedOrder?.id, 'order-1');
  });

  testWidgets('marks unavailable items returned during order creation', (
    tester,
  ) async {
    final cartVM = _FakeCartViewModel();

    await tester.pumpWidget(
      _Harness(
        cartVM: cartVM,
        button: CartPaymentButton(
          group: _group,
          restaurantOpenChecker: (_, __) async => true,
          openDeliveryForm: (_, __, ___) async => true,
          createOrder: (_, __, ___, ____) async => throw OrderCreationException(
            statusCode: 409,
            body: 'unavailable',
            unavailableItems: ['Burger', 'Frites'],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Payer'));
    await tester.pump();

    expect(cartVM.unavailableByRestaurant['restaurant-1'], [
      'Burger',
      'Frites',
    ]);
    expect(
      find.text('Indisponible pour le moment : Burger, Frites'),
      findsOneWidget,
    );
  });

  testWidgets(
      'clears the cart and returns to the listing without naming the suspension',
      (
    tester,
  ) async {
    final cartVM = _FakeCartViewModel();
    var returnedToListing = 0;

    await tester.pumpWidget(
      _Harness(
        cartVM: cartVM,
        button: CartPaymentButton(
          group: _group,
          restaurantOpenChecker: (_, __) async => true,
          openDeliveryForm: (_, __, ___) async => true,
          returnToListing: (_) => returnedToListing++,
          createOrder: (_, __, ___, ____) async => throw OrderCreationException(
            statusCode: 409,
            body: 'suspended',
            code: 'RESTAURANT_SUSPENDED',
          ),
        ),
      ),
    );

    await tester.tap(find.text('Payer'));
    await tester.pump();

    expect(find.text('Ce restaurant n\'est plus disponible.'), findsOneWidget);
    expect(cartVM.removedRestaurantIds, ['restaurant-1']);
    expect(returnedToListing, 1);
    expect(find.textContaining('suspend'), findsNothing);
  });

  testWidgets('keeps the cart for an unrelated 409', (tester) async {
    final cartVM = _FakeCartViewModel();
    var returnedToListing = 0;

    await tester.pumpWidget(
      _Harness(
        cartVM: cartVM,
        button: CartPaymentButton(
          group: _group,
          restaurantOpenChecker: (_, __) async => true,
          openDeliveryForm: (_, __, ___) async => true,
          returnToListing: (_) => returnedToListing++,
          createOrder: (_, __, ___, ____) async => throw OrderCreationException(
            statusCode: 409,
            body: 'other',
            code: 'SOMETHING_ELSE',
          ),
        ),
      ),
    );

    await tester.tap(find.text('Payer'));
    await tester.pump();

    expect(cartVM.removedRestaurantIds, isEmpty);
    expect(returnedToListing, 0);
    expect(
      find.text('Impossible de créer la commande. Veuillez réessayer.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'uses wallet payload and confirms without gateway when balance covers total',
    (tester) async {
      final cartVM = _FakeCartViewModel();
      final paymentService = _FakePaymentService(PaymentStatus.success);
      Order? confirmedOrder;
      var gatewayOpened = false;

      await tester.pumpWidget(
        _Harness(
          cartVM: cartVM,
          paymentVM: PaymentViewModel(
            PaymentRepository(service: paymentService),
          ),
          walletBalance: 40000,
          button: CartPaymentButton(
            group: _group,
            restaurantOpenChecker: (_, __) async => true,
            openDeliveryForm: (_, __, ___) async => true,
            createOrder: (_, __, ___, ____) async => _order,
            openPaymentGateway: (_, __) async {
              gatewayOpened = true;
              return PaymentGatewayResult.success;
            },
            onPaymentConfirmed: (_, __, ___, order) => confirmedOrder = order,
          ),
        ),
      );

      await tester.tap(find.text('Payer'));
      await _confirmPaymentMethod(tester, CheckoutPaymentMethod.wallet);

      expect(paymentService.createdPayload, {
        'customerId': 'customer-1',
        'orderId': 'order-1',
        'amount': 35000.0,
        'paymentMethod': 'WALLET',
        'walletAmount': 35000.0,
      });
      expect(gatewayOpened, isFalse);
      expect(confirmedOrder?.id, 'order-1');
      expect(cartVM.consumedDeliveryConfirmation, isTrue);
    },
  );
}

Future<void> _confirmPaymentMethod(
  WidgetTester tester,
  CheckoutPaymentMethod method,
) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  if (method == CheckoutPaymentMethod.djomy) {
    await tester.tap(find.text('Mobile Money'));
    await tester.pump();
  }
  await tester.tap(_textContainingNormalized('Payer ').last);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Finder _textContainingNormalized(String expected) {
  return find.byWidgetPredicate((widget) {
    final text = widget is Text ? widget.data : null;
    return _normalize(text).contains(expected);
  });
}

String _normalize(String? value) {
  return value
          ?.replaceAll('\u00A0', ' ')
          .replaceAll('\u202F', ' ')
          .replaceAll(RegExp(r'\s+'), ' ') ??
      '';
}

class _Harness extends StatelessWidget {
  const _Harness({
    required this.cartVM,
    this.button,
    this.includeCurrentUser = true,
    this.paymentVM,
    this.walletBalance = 10000,
  });

  final CartViewModel cartVM;
  final Widget? button;
  final bool includeCurrentUser;
  final PaymentViewModel? paymentVM;
  final double walletBalance;

  @override
  Widget build(BuildContext context) {
    final currentUserVM = CurrentUserViewModel();
    if (includeCurrentUser) {
      currentUserVM.setUser(_user);
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CartViewModel>.value(value: cartVM),
        ChangeNotifierProvider<CurrentUserViewModel>.value(
          value: currentUserVM,
        ),
        ChangeNotifierProvider<PaymentViewModel>.value(
          value:
              paymentVM ??
              PaymentViewModel(PaymentRepository(service: PaymentService())),
        ),
        ChangeNotifierProvider<WalletViewModel>(
          create: (_) => WalletViewModel(
            WalletRepository(
              service: _FakeWalletService(balance: walletBalance),
            ),
          ),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Center(child: button ?? CartPaymentButton(group: _group)),
        ),
      ),
    );
  }
}

class _FakeCartViewModel extends CartViewModel {
  _FakeCartViewModel({
    this.hasEstimation = true,
    this.firstName = 'Aminata',
    this.phoneNumber = '620 00 00 00',
    this.address = 'Rue 12',
    this.district = 'Kipé',
  });

  final bool hasEstimation;
  bool confirmed = true;
  final String? firstName;
  final String? phoneNumber;
  final String? address;
  final String? district;
  final List<String> removedRestaurantIds = [];
  final Map<String, List<String>> unavailableByRestaurant = {};
  bool consumedDeliveryConfirmation = false;

  @override
  bool hasEstimationFor(String restaurantId) => hasEstimation;

  @override
  bool isEstimating(String restaurantId) => false;

  @override
  double? totalFor(CartGroup group) => 35000;

  @override
  bool get isDeliveryConfirmedForCurrentOrder => confirmed;

  @override
  String? get deliveryFirstName => firstName;

  @override
  String? get deliveryPhoneNumber => phoneNumber;

  @override
  String? get deliveryAddress => address;

  @override
  String? get deliveryDistrict => district;

  @override
  void consumeDeliveryConfirmation() {
    confirmed = false;
    consumedDeliveryConfirmation = true;
  }

  @override
  void removeCartGroup(String restaurantId) {
    removedRestaurantIds.add(restaurantId);
  }

  @override
  void clearUnavailableItemsForRestaurant(String restaurantId) {
    unavailableByRestaurant.remove(restaurantId);
  }

  @override
  void markUnavailableItems(String restaurantId, List<String> itemNames) {
    unavailableByRestaurant[restaurantId] = itemNames;
  }
}

class _FakePaymentViewModel extends PaymentViewModel {
  _FakePaymentViewModel(this.statuses)
    : super(PaymentRepository(service: PaymentService()));

  final List<PaymentStatus> statuses;
  final List<String> refreshedIds = [];

  @override
  Future<Payment?> refresh(String paymentId) async {
    refreshedIds.add(paymentId);
    final status = statuses.length >= refreshedIds.length
        ? statuses[refreshedIds.length - 1]
        : PaymentStatus.unknown;
    return Payment(
      id: paymentId,
      customerId: 'customer-1',
      orderId: 'order-1',
      status: status,
      amount: 35000,
      paymentToken: 'token-1',
    );
  }
}

class _FakeWalletService extends WalletService {
  final double balance;

  _FakeWalletService({required this.balance});

  @override
  Future<Map<String, dynamic>> getWallet(String customerId) async {
    return {
      'id': 'wallet-1',
      'customerId': customerId,
      'balance': balance,
      'currency': 'GNF',
      'transactions': [],
    };
  }
}

class _FakePaymentService extends PaymentService {
  final PaymentStatus status;
  Map<String, dynamic>? createdPayload;

  _FakePaymentService(this.status);

  @override
  Future<Map<String, dynamic>> createPayment(
    Map<String, dynamic> payload,
  ) async {
    createdPayload = payload;
    return {
      'id': 'payment-1',
      'customerId': payload['customerId'],
      'orderId': payload['orderId'],
      'amount': payload['amount'],
      'currency': 'GNF',
      'status': switch (status) {
        PaymentStatus.success => 'COMPLETED',
        PaymentStatus.failed => 'FAILED',
        PaymentStatus.canceled => 'CANCELED',
        PaymentStatus.pending => 'PENDING',
        PaymentStatus.unknown => 'UNKNOWN',
      },
      'paymentToken': 'token-1',
    };
  }
}

final _product = Product(
  id: 'product-1',
  name: 'Burger',
  price: 15000,
  imageUrl: '',
  category: 'product',
  restaurantId: 'restaurant-1',
  restaurantName: 'Chez Mariam',
);

final _group = CartGroup(
  restaurantId: 'restaurant-1',
  restaurantName: 'Chez Mariam',
  deliveryAddress: 'Rue 12, Kipé',
  items: [CartItem(product: _product, quantity: 2)],
);

final _order = Order(
  id: 'order-1',
  shortId: 'A123',
  restaurantId: 'restaurant-1',
  restaurantName: 'Chez Mariam',
  totalPrice: 35000,
  serviceFee: 1000,
  deliveryFee: 5000,
  deliveryContact: const OrderDeliveryContact(
    phoneNumber: '620000000',
    address: 'Rue 12',
    district: 'Kipé',
    commune: 'Ratoma',
    firstName: 'Aminata',
    lastName: 'Diallo',
  ),
  status: OrderStatus.created,
  createdDate: DateTime(2026, 1, 1),
  lastModifiedDate: DateTime(2026, 1, 1),
  items: const [],
  customerId: 'customer-1',
);

final _payment = Payment(
  id: 'payment-1',
  customerId: 'customer-1',
  orderId: 'order-1',
  status: PaymentStatus.pending,
  amount: 35000,
  paymentToken: 'token-1',
);

final _user = User(
  id: 'customer-1',
  firstName: 'Aminata',
  lastName: 'Diallo',
  phoneNumber: '620000000',
  role: 'CUSTOMER',
  isTemporaryPin: false,
);
