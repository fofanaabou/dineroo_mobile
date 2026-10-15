import 'package:dineroo_mobile/shared/common/helpers/order_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('order helpers', () {
    test('extracts short order id from uuid-like values', () {
      expect(getShortOrderId('order-2026-ABCD'), 'ABCD');
      expect(getShortOrderId('  only-one-segment  '), 'segment');
    });

    test('formats order references with fallback labels', () {
      expect(formatOrderReference('order-1234'), 'Commande #1234');
      expect(formatOrderReference(''), 'Commande');
      expect(formatOrderReferenceNumber('order-1234'), '#1234');
      expect(formatOrderReferenceNumber(null), '-');
    });

    test('uses custom display names when provided', () {
      expect(getOrderDisplayName('order-1234', 'Déjeuner'), 'Déjeuner');
      expect(getOrderDisplayName('order-1234', '  '), 'Commande #1234');
      expect(getOrderItemDisplayName(7, 'Burger'), 'Burger');
      expect(getOrderItemDisplayName(7, ''), 'Article #7');
    });
  });
}
