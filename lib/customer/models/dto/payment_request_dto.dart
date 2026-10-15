class PaymentRequestDto {
  final String customerId;
  final String orderId;
  final double amount;
  final String? paymentMethod;
  final double walletAmount;

  PaymentRequestDto({
    required this.customerId,
    required this.orderId,
    required this.amount,
    this.paymentMethod,
    this.walletAmount = 0,
  });

  Map<String, dynamic> toJson() => {
    'customerId': customerId,
    'orderId': orderId,
    'amount': amount,
    if (paymentMethod != null) 'paymentMethod': paymentMethod,
    'walletAmount': walletAmount,
  };
}
