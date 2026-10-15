import 'dart:async';
import 'dart:convert';

import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/models/domain/order_event.dart';
import 'package:dineroo_mobile/shared/realtime/stomp_realtime_service.dart';
import 'package:flutter/foundation.dart';

class CustomerOrderRealtimeService {
  static final CustomerOrderRealtimeService _instance =
      CustomerOrderRealtimeService._internal();

  factory CustomerOrderRealtimeService() => _instance;

  CustomerOrderRealtimeService._internal();

  @visibleForTesting
  static StompRealtimeService? stompServiceOverride;

  StompRealtimeService get _stomp =>
      stompServiceOverride ?? StompRealtimeService();

  final StreamController<OrderEvent> _controller =
      StreamController<OrderEvent>.broadcast();

  Stream<OrderEvent> get stream => _controller.stream;

  String? _currentDestination;

  Future<void> subscribeToOrderStatus({
    required String customerId,
    required String orderId,
  }) async {
    final destination = '/topic/$customerId/orders/$orderId/status';

    if (_currentDestination == destination) {
      logger.i('[RT][Customer] Already subscribed to $destination');
      return;
    }

    if (_currentDestination != null) {
      _stomp.unsubscribe(_currentDestination!);
    }

    _currentDestination = destination;

    await _stomp.subscribe(
      destination: destination,
      onMessage: (body) {
        try {
          final event = OrderEvent.fromJson(jsonDecode(body));
          logger.i(
            '[RT][Customer] Event received for order ${event.orderId}: ${event.status}',
          );
          _controller.add(event);
        } catch (e, stack) {
          logger.e(
            '[RT][Customer] Failed to parse event',
            error: e,
            stackTrace: stack,
          );
        }
      },
    );
  }

  void clearCurrentSubscription() {
    if (_currentDestination != null) {
      _stomp.unsubscribe(_currentDestination!);
      _currentDestination = null;
    }
  }
}
