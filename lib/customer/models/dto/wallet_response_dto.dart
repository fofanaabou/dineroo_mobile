import 'package:dineroo_mobile/customer/models/domain/wallet.dart';
import 'package:dineroo_mobile/customer/models/domain/wallet_transaction.dart';

class WalletResponseDto {
  final String id;
  final String customerId;
  final double balance;
  final String currency;
  final List<WalletTransactionDto> transactions;

  WalletResponseDto({
    required this.id,
    required this.customerId,
    required this.balance,
    required this.currency,
    required this.transactions,
  });

  factory WalletResponseDto.fromJson(Map<String, dynamic> json) {
    final transactionsJson = json['transactions'];
    return WalletResponseDto(
      id: (json['id'] ?? '').toString(),
      customerId: (json['customerId'] ?? '').toString(),
      balance: ((json['balance'] as num?) ?? 0).toDouble(),
      currency: (json['currency'] ?? 'GNF').toString(),
      transactions: transactionsJson is List
          ? transactionsJson
                .whereType<Map<String, dynamic>>()
                .map(WalletTransactionDto.fromJson)
                .toList()
          : const [],
    );
  }

  Wallet toDomain() {
    return Wallet(
      id: id,
      customerId: customerId,
      balance: balance,
      currency: currency,
      transactions: transactions.map((transaction) => transaction.toDomain()).toList(),
    );
  }
}

class WalletTransactionDto {
  final String id;
  final String customerId;
  final String? paymentId;
  final double amount;
  final String currency;
  final String type;
  final String reference;
  final String reason;
  final DateTime? createdAt;

  WalletTransactionDto({
    required this.id,
    required this.customerId,
    required this.paymentId,
    required this.amount,
    required this.currency,
    required this.type,
    required this.reference,
    required this.reason,
    required this.createdAt,
  });

  factory WalletTransactionDto.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt']?.toString();
    return WalletTransactionDto(
      id: (json['id'] ?? '').toString(),
      customerId: (json['customerId'] ?? '').toString(),
      paymentId: json['paymentId']?.toString(),
      amount: ((json['amount'] as num?) ?? 0).toDouble(),
      currency: (json['currency'] ?? 'GNF').toString(),
      type: (json['type'] ?? '').toString(),
      reference: (json['reference'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
      createdAt: createdAt == null ? null : DateTime.tryParse(createdAt),
    );
  }

  WalletTransaction toDomain() {
    return WalletTransaction(
      id: id,
      customerId: customerId,
      paymentId: paymentId,
      amount: amount,
      currency: currency,
      type: type,
      reference: reference,
      reason: reason,
      createdAt: createdAt,
    );
  }
}
