import 'package:dineroo_mobile/customer/enums/payment_status.dart';
import 'package:dineroo_mobile/customer/models/dto/payment_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaymentResponseDto', () {
    test('parses JSON and converts numeric amount to double', () {
      final dto = PaymentResponseDto.fromJson({
        'id': 123,
        'customerId': 'customer-1',
        'orderId': 'order-1',
        'status': 'COMPLETED',
        'amount': 5000,
        'currency': 'GNF',
        'paymentToken': 'token-1',
      });

      expect(dto.id, '123');
      expect(dto.customerId, 'customer-1');
      expect(dto.orderId, 'order-1');
      expect(dto.status, 'COMPLETED');
      expect(dto.amount, 5000.0);
      expect(dto.currency, 'GNF');
      expect(dto.paymentToken, 'token-1');
    });

    test('uses safe defaults for nullable JSON fields', () {
      final dto = PaymentResponseDto.fromJson({});

      expect(dto.id, '');
      expect(dto.customerId, '');
      expect(dto.orderId, '');
      expect(dto.status, isNull);
      expect(dto.amount, 0.0);
      expect(dto.currency, isNull);
      expect(dto.paymentToken, '');
    });

    test('converts to domain payment with parsed status', () {
      final payment = PaymentResponseDto.fromJson({
        'id': 'payment-1',
        'customerId': 'customer-1',
        'orderId': 'order-1',
        'status': ' failed ',
        'amount': 1500.75,
        'currency': 'GNF',
        'paymentToken': 'token-1',
      }).toDomain();

      expect(payment.id, 'payment-1');
      expect(payment.status, PaymentStatus.failed);
      expect(payment.amount, 1500.75);
      expect(payment.currency, 'GNF');
      expect(payment.paymentToken, 'token-1');
    });
  });
}
