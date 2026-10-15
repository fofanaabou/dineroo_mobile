import 'package:dineroo_mobile/shared/enums/order_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderStatus', () {
    test('parses backend values regardless of casing and spaces', () {
      expect(OrderStatus.fromString(' created '), OrderStatus.created);
      expect(
        OrderStatus.fromString('PENDING_PAYMENT'),
        OrderStatus.pendingPayment,
      );
      expect(OrderStatus.fromString('READY'), OrderStatus.readyForPickup);
      expect(
        OrderStatus.fromString('READY_FOR_PICKUP'),
        OrderStatus.readyForPickup,
      );
      expect(OrderStatus.fromString('COMPLETED'), OrderStatus.completed);
    });

    test('throws on unsupported backend value', () {
      expect(
        () => OrderStatus.fromString('UNKNOWN_STATUS'),
        throwsA(isA<FormatException>()),
      );
    });

    test('returns API values for all statuses', () {
      expect(OrderStatus.created.apiValue, 'CREATED');
      expect(OrderStatus.pendingPayment.apiValue, 'PENDING_PAYMENT');
      expect(OrderStatus.paymentConfirmed.apiValue, 'PAYMENT_CONFIRMED');
      expect(OrderStatus.paymentFailed.apiValue, 'PAYMENT_FAILED');
      expect(OrderStatus.accepted.apiValue, 'ACCEPTED');
      expect(OrderStatus.rejected.apiValue, 'REJECTED');
      expect(OrderStatus.preparing.apiValue, 'PREPARING');
      expect(OrderStatus.readyForPickup.apiValue, 'READY_FOR_PICKUP');
      expect(OrderStatus.pickedUp.apiValue, 'PICKED_UP');
      expect(OrderStatus.delivered.apiValue, 'DELIVERED');
      expect(OrderStatus.completed.apiValue, 'COMPLETED');
      expect(OrderStatus.canceled.apiValue, 'CANCELED');
    });

    test('classifies ongoing, history, failure and delivery steps', () {
      expect(OrderStatus.accepted.isOngoing, isTrue);
      expect(OrderStatus.delivered.isOngoing, isFalse);
      expect(OrderStatus.delivered.isHistory, isTrue);
      expect(OrderStatus.canceled.isFailure, isTrue);
      expect(OrderStatus.preparing.hasReachedConfirmedStep, isTrue);
      expect(OrderStatus.readyForPickup.hasReachedDeliveryStep, isFalse);
      expect(OrderStatus.pickedUp.hasReachedDeliveryStep, isTrue);
      expect(OrderStatus.completed.isDeliveredOrCompleted, isTrue);
    });
  });
}
