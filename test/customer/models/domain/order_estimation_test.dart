import 'package:dineroo_mobile/customer/models/domain/order_estimation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderEstimation', () {
    test('parses numeric values as doubles', () {
      final estimation = OrderEstimation.fromJson({
        'subtotal': 10000,
        'serviceFee': 500.5,
        'deliveryFee': 3000,
        'total': 13500.5,
        'djomyFee': 200,
      });

      expect(estimation.subtotal, 10000);
      expect(estimation.serviceFee, 500.5);
      expect(estimation.deliveryFee, 3000);
      expect(estimation.total, 13500.5);
      expect(estimation.djomyFee, 200);
    });

    test('uses zero defaults and nullable djomy fee', () {
      final estimation = OrderEstimation.fromJson({});

      expect(estimation.subtotal, 0);
      expect(estimation.serviceFee, 0);
      expect(estimation.deliveryFee, 0);
      expect(estimation.total, 0);
      expect(estimation.djomyFee, isNull);
    });
  });
}
