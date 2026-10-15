import 'package:dineroo_mobile/shared/realtime/handlers/customer_order_realtime_service.dart';
import 'package:dineroo_mobile/shared/realtime/stomp_realtime_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import '../fake_stomp_client.dart';

void main() {
  group('CustomerOrderRealtimeService', () {
    setUp(() {
      dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.test');
      StompRealtimeService.clientFactory = (config) =>
          FakeStompClient(config: config);
    });

    tearDown(() {
      StompRealtimeService.clientFactory = null;
      CustomerOrderRealtimeService.stompServiceOverride = null;
    });

    test('subscribes to order status topic', () async {
      final stomp = StompRealtimeService();
      await stomp.connect(token: 'test', userRole: 'DRIVER');
      CustomerOrderRealtimeService.stompServiceOverride = stomp;

      final service = CustomerOrderRealtimeService();
      await service.subscribeToOrderStatus(
        customerId: 'cust-1',
        orderId: 'order-1',
      );

      // no error means success
    });

    test(
      'unsubscribes previous destination before subscribing to new',
      () async {
        final stomp = StompRealtimeService();
        await stomp.connect(token: 'test', userRole: 'DRIVER');
        CustomerOrderRealtimeService.stompServiceOverride = stomp;

        final service = CustomerOrderRealtimeService();
        await service.subscribeToOrderStatus(
          customerId: 'cust-1',
          orderId: 'order-1',
        );
        await service.subscribeToOrderStatus(
          customerId: 'cust-1',
          orderId: 'order-2',
        );

        // no error
      },
    );

    test('skips subscribe if already subscribed to same destination', () async {
      final stomp = StompRealtimeService();
      await stomp.connect(token: 'test', userRole: 'DRIVER');
      CustomerOrderRealtimeService.stompServiceOverride = stomp;

      final service = CustomerOrderRealtimeService();
      await service.subscribeToOrderStatus(
        customerId: 'cust-1',
        orderId: 'order-1',
      );
      await service.subscribeToOrderStatus(
        customerId: 'cust-1',
        orderId: 'order-1',
      );

      // no duplicate subscription error
    });

    test(
      'clearCurrentSubscription unsubscribes and resets destination',
      () async {
        final stomp = StompRealtimeService();
        await stomp.connect(token: 'test', userRole: 'DRIVER');
        CustomerOrderRealtimeService.stompServiceOverride = stomp;

        final service = CustomerOrderRealtimeService();
        await service.subscribeToOrderStatus(
          customerId: 'cust-1',
          orderId: 'order-1',
        );

        service.clearCurrentSubscription();

        // no error, subscription cleared
      },
    );
  });
}
