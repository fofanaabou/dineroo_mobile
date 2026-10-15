import 'package:dineroo_mobile/customer/repositories/wallet_repository.dart';
import 'package:dineroo_mobile/customer/services/wallet/wallet_service.dart';
import 'package:dineroo_mobile/customer/view_models/wallet/wallet_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WalletViewModel', () {
    late _FakeWalletService service;
    late WalletViewModel viewModel;

    setUp(() {
      service = _FakeWalletService();
      viewModel = WalletViewModel(WalletRepository(service: service));
    });

    test('loads wallet, stores it and notifies loading changes', () async {
      final states = <bool>[];
      viewModel.addListener(() => states.add(viewModel.isLoading));

      final wallet = await viewModel.getWallet('customer-1');

      expect(service.requestedCustomerId, 'customer-1');
      expect(wallet.id, 'wallet-1');
      expect(wallet.balance, 25000.0);
      expect(viewModel.wallet, wallet);
      expect(viewModel.error, isNull);
      expect(states, [true, false]);
    });

    test('keeps error and clears loading when loading fails', () async {
      service.exception = Exception('wallet unavailable');

      await expectLater(
        () => viewModel.getWallet('customer-1'),
        throwsException,
      );

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.error, contains('wallet unavailable'));
      expect(viewModel.wallet, isNull);
    });
  });
}

class _FakeWalletService extends WalletService {
  String? requestedCustomerId;
  Object? exception;

  @override
  Future<Map<String, dynamic>> getWallet(String customerId) async {
    requestedCustomerId = customerId;
    final exception = this.exception;
    if (exception != null) throw exception;
    return {
      'id': 'wallet-1',
      'customerId': customerId,
      'balance': 25000,
      'currency': 'GNF',
      'transactions': [],
    };
  }
}
