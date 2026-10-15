class WalletTransaction {
  final String id;
  final String customerId;
  final String? paymentId;
  final double amount;
  final String currency;
  final String type;
  final String reference;
  final String reason;
  final DateTime? createdAt;

  WalletTransaction({
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
}
