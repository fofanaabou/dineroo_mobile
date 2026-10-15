import 'package:dineroo_mobile/customer/models/dto/payment_request_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaymentRequestDto', () {
    test('serializes payment request with the provided amount', () {
      final dto = PaymentRequestDto(
        customerId: 'customer-1',
        orderId: 'order-1',
        amount: 12500.5,
      );

      expect(dto.toJson(), {
        'customerId': 'customer-1',
        'orderId': 'order-1',
        'amount': 12500.5,
        'walletAmount': 0.0,
      });
    });

    test('serializes wallet split payment fields when provided', () {
      final dto = PaymentRequestDto(
        customerId: 'customer-1',
        orderId: 'order-1',
        amount: 35000,
        paymentMethod: 'WALLET',
        walletAmount: 12000,
      );

      expect(dto.toJson(), {
        'customerId': 'customer-1',
        'orderId': 'order-1',
        'amount': 35000.0,
        'paymentMethod': 'WALLET',
        'walletAmount': 12000.0,
      });
    });
  });
}
