import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:dineroo_mobile/customer/repositories/wallet_repository.dart';
import 'package:dineroo_mobile/customer/services/wallet/wallet_service.dart';
import 'package:dineroo_mobile/customer/view_models/wallet/wallet_view_model.dart';
import 'package:dineroo_mobile/customer/views/wallet/customer_wallet_view.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  group('CustomerWalletView', () {
    testWidgets('loads and renders balance plus transaction history', (
      tester,
    ) async {
      final service = _FakeWalletService();

      await tester.pumpWidget(_Harness(service: service, user: _user));
      await tester.pumpAndSettle();

      expect(service.requestedCustomerIds, ['customer-1']);
      expect(find.text('Mon Wallet'), findsOneWidget);
      expect(_textContainingNormalized('42 000 GNF'), findsOneWidget);
      expect(find.text('Historique'), findsOneWidget);
      expect(find.text('Remboursement commande'), findsOneWidget);
      expect(find.text('Paiement commande'), findsOneWidget);
      expect(_textContainingNormalized('+15 000 GNF'), findsOneWidget);
      expect(_textContainingNormalized('-8 000 GNF'), findsOneWidget);
      expect(find.text('REF-CREDIT'), findsOneWidget);
    });

    testWidgets('renders empty history when wallet has no transactions', (
      tester,
    ) async {
      final service = _FakeWalletService(transactions: const []);

      await tester.pumpWidget(_Harness(service: service, user: _user));
      await tester.pumpAndSettle();

      expect(find.text('Aucune transaction pour le moment.'), findsOneWidget);
    });

    testWidgets('renders retry error when current user is missing', (
      tester,
    ) async {
      await tester.pumpWidget(_Harness(service: _FakeWalletService()));
      await tester.pumpAndSettle();

      expect(find.text('Impossible de charger votre Wallet.'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('loads wallet when current user becomes available later', (
      tester,
    ) async {
      final service = _FakeWalletService();
      final currentUserVM = CurrentUserViewModel();

      await tester.pumpWidget(
        _Harness(service: service, currentUserVM: currentUserVM),
      );
      await tester.pumpAndSettle();
      expect(service.requestedCustomerIds, isEmpty);

      currentUserVM.setUser(_user);
      await tester.pumpAndSettle();

      expect(service.requestedCustomerIds, ['customer-1']);
      expect(_textContainingNormalized('42 000 GNF'), findsOneWidget);
    });

    testWidgets('keeps the error state visible when loading fails', (
      tester,
    ) async {
      final service = _FakeWalletService(exception: Exception('backend down'));

      await tester.pumpWidget(_Harness(service: service, user: _user));
      await tester.pumpAndSettle();

      expect(find.text('Impossible de charger votre Wallet.'), findsOneWidget);
    });
  });
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
  final _FakeWalletService service;
  final User? user;
  final CurrentUserViewModel? currentUserVM;

  const _Harness({required this.service, this.user, this.currentUserVM});

  @override
  Widget build(BuildContext context) {
    final currentUserVM = this.currentUserVM ?? CurrentUserViewModel();
    final user = this.user;
    if (user != null) currentUserVM.setUser(user);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CurrentUserViewModel>.value(
          value: currentUserVM,
        ),
        ChangeNotifierProvider<WalletViewModel>(
          create: (_) => WalletViewModel(WalletRepository(service: service)),
        ),
      ],
      child: const MaterialApp(home: CustomerWalletView()),
    );
  }
}

class _FakeWalletService extends WalletService {
  final Object? exception;
  final List<Map<String, dynamic>> transactions;
  final List<String> requestedCustomerIds = [];

  _FakeWalletService({this.exception, List<Map<String, dynamic>>? transactions})
    : transactions = transactions ?? _defaultTransactions;

  @override
  Future<Map<String, dynamic>> getWallet(String customerId) async {
    requestedCustomerIds.add(customerId);
    final exception = this.exception;
    if (exception != null) throw exception;
    return {
      'id': 'wallet-1',
      'customerId': customerId,
      'balance': 42000,
      'currency': 'GNF',
      'transactions': transactions,
    };
  }
}

final _defaultTransactions = [
  {
    'id': 'transaction-1',
    'customerId': 'customer-1',
    'amount': 15000,
    'currency': 'GNF',
    'type': 'CREDIT',
    'reference': 'REF-CREDIT',
    'reason': 'Remboursement commande',
    'createdAt': '2026-08-14T10:00:00.000Z',
  },
  {
    'id': 'transaction-2',
    'customerId': 'customer-1',
    'amount': 8000,
    'currency': 'GNF',
    'type': 'DEBIT',
    'reference': 'REF-DEBIT',
    'reason': 'Paiement commande',
    'createdAt': null,
  },
];

final _user = User(
  id: 'customer-1',
  firstName: 'Aminata',
  lastName: 'Diallo',
  phoneNumber: '620000000',
  role: 'CUSTOMER',
  isTemporaryPin: false,
);
