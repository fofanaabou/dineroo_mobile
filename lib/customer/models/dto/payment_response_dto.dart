import 'package:dineroo_mobile/customer/enums/payment_status.dart';
import 'package:dineroo_mobile/customer/models/domain/payment.dart';

class PaymentResponseDto {
  final String id;
  final String customerId;
  final String orderId;
  final String? status;
  final double amount;
  final String? currency;
  final String paymentToken;

  PaymentResponseDto({
    required this.id,
    required this.customerId,
    required this.orderId,
    required this.status,
    required this.amount,
    required this.currency,
    required this.paymentToken,
  });

  factory PaymentResponseDto.fromJson(Map<String, dynamic> json) {
    return PaymentResponseDto(
      id: (json['id'] ?? '').toString(),
      customerId: (json['customerId'] ?? '').toString(),
      orderId: (json['orderId'] ?? '').toString(),
      status: json['status']?.toString(),
      amount: ((json['amount'] as num?) ?? 0.0).toDouble(),
      currency: json['currency']?.toString(),
      paymentToken: (json['paymentToken'] ?? '').toString(),
    );
  }

  Payment toDomain() {
    return Payment(
      id: id,
      customerId: customerId,
      orderId: orderId,
      status: PaymentStatus.fromApi(status),
      amount: amount,
      currency: currency,
      paymentToken: paymentToken,
    );
  }
}
