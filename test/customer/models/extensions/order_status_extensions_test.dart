import 'package:dineroo_mobile/customer/models/extensions/order_status_extensions.dart';
import 'package:dineroo_mobile/shared/enums/order_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CustomerOrderStatusExtensions', () {
    test('keeps only final customer statuses in history', () {
      expect(OrderStatus.delivered.isCustomerHistory, isTrue);
      expect(OrderStatus.completed.isCustomerHistory, isTrue);
      expect(OrderStatus.rejected.isCustomerHistory, isTrue);
      expect(OrderStatus.paymentFailed.isCustomerHistory, isTrue);
      expect(OrderStatus.canceled.isCustomerHistory, isTrue);

      expect(OrderStatus.pickedUp.isCustomerHistory, isFalse);
      expect(OrderStatus.accepted.isCustomerHistory, isFalse);
      expect(OrderStatus.preparing.isCustomerHistory, isFalse);
      expect(OrderStatus.readyForPickup.isCustomerHistory, isFalse);
    });

    test('keeps every non-final customer status ongoing', () {
      expect(OrderStatus.pickedUp.isCustomerOngoing, isTrue);
      expect(OrderStatus.accepted.isCustomerOngoing, isTrue);
      expect(OrderStatus.preparing.isCustomerOngoing, isTrue);
      expect(OrderStatus.readyForPickup.isCustomerOngoing, isTrue);

      expect(OrderStatus.delivered.isCustomerOngoing, isFalse);
      expect(OrderStatus.completed.isCustomerOngoing, isFalse);
      expect(OrderStatus.rejected.isCustomerOngoing, isFalse);
      expect(OrderStatus.paymentFailed.isCustomerOngoing, isFalse);
      expect(OrderStatus.canceled.isCustomerOngoing, isFalse);
    });
  });
}
