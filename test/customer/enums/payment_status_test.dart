import 'package:dineroo_mobile/customer/enums/payment_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaymentStatus', () {
    test('parses known API values regardless of casing and spaces', () {
      expect(PaymentStatus.fromApi(' pending '), PaymentStatus.pending);
      expect(PaymentStatus.fromApi('completed'), PaymentStatus.success);
      expect(PaymentStatus.fromApi('FAILED'), PaymentStatus.failed);
      expect(PaymentStatus.fromApi('canceled'), PaymentStatus.canceled);
    });

    test('returns unknown for null or unsupported values', () {
      expect(PaymentStatus.fromApi(null), PaymentStatus.unknown);
      expect(PaymentStatus.fromApi('paid'), PaymentStatus.unknown);
    });
  });
}
