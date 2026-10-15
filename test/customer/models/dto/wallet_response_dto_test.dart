import 'package:dineroo_mobile/customer/models/dto/wallet_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WalletResponseDto', () {
    test('maps wallet response and transactions to domain objects', () {
      final dto = WalletResponseDto.fromJson({
        'id': 'wallet-1',
        'customerId': 'customer-1',
        'balance': 42500,
        'currency': 'GNF',
        'transactions': [
          {
            'id': 'transaction-1',
            'customerId': 'customer-1',
            'paymentId': 'payment-1',
            'amount': 15000,
            'currency': 'GNF',
            'type': 'CREDIT',
            'reference': 'REF-1',
            'reason': 'Remboursement commande',
            'createdAt': '2026-08-14T10:15:00.000Z',
          },
        ],
      });

      final wallet = dto.toDomain();

      expect(wallet.id, 'wallet-1');
      expect(wallet.customerId, 'customer-1');
      expect(wallet.balance, 42500.0);
      expect(wallet.currency, 'GNF');
      expect(wallet.transactions, hasLength(1));
      expect(wallet.transactions.single.id, 'transaction-1');
      expect(wallet.transactions.single.paymentId, 'payment-1');
      expect(
        wallet.transactions.single.createdAt,
        DateTime.utc(2026, 8, 14, 10, 15),
      );
    });

    test('uses safe defaults and ignores non-map transactions', () {
      final dto = WalletResponseDto.fromJson({
        'transactions': [
          'invalid',
          {'amount': null, 'createdAt': 'not-a-date'},
        ],
      });

      final wallet = dto.toDomain();

      expect(wallet.id, '');
      expect(wallet.customerId, '');
      expect(wallet.balance, 0.0);
      expect(wallet.currency, 'GNF');
      expect(wallet.transactions, hasLength(1));
      expect(wallet.transactions.single.amount, 0.0);
      expect(wallet.transactions.single.createdAt, isNull);
    });
  });
}
