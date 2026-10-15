import 'package:dineroo_mobile/customer/models/domain/wallet_transaction.dart';

class Wallet {
  final String id;
  final String customerId;
  final double balance;
  final String currency;
  final List<WalletTransaction> transactions;

  Wallet({
    required this.id,
    required this.customerId,
    required this.balance,
    required this.currency,
    this.transactions = const [],
  });
}
