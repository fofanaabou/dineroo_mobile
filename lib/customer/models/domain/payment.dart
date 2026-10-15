import 'package:dineroo_mobile/customer/enums/payment_status.dart';

class Payment {
  final String id;
  final String customerId;
  final String orderId;
  final PaymentStatus status;
  final double amount;
  final String? currency;
  final String paymentToken;

  Payment({
    required this.id,
    required this.customerId,
    required this.orderId,
    required this.status,
    required this.amount,
    required this.paymentToken,
    this.currency,
  });
}
