import 'dart:convert';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/models/domain/order_event.dart';
import 'package:dineroo_mobile/shared/realtime/handlers/restaurant_event_handler.dart';
import 'package:dineroo_mobile/shared/realtime/handlers/driver_event_handler.dart';
import 'package:dineroo_mobile/shared/realtime/stomp_realtime_service.dart';
import 'package:dineroo_mobile/driver/models/domain/driver_delivery_event.dart';

class StompSubscriptionManager {
  final StompRealtimeService _service;

  StompSubscriptionManager(this._service);

  void autoSubscribeForRole(
    String userRole,
    String? restaurantId,
    String? userId,
  ) {
    switch (userRole.toUpperCase()) {
      case 'RESTAURANT_MANAGER':
        if (restaurantId != null && restaurantId.isNotEmpty) {
          final topic = '/topic/restaurants/$restaurantId';
          _service.subscribe(destination: topic, onMessage: _onRestaurantEvent);
        }
        break;

      case 'DRIVER':
      case 'COURIER':
      case 'DELIVERY_DRIVER':
        if (userId != null && userId.isNotEmpty) {
          final topic = '/topic/drivers/$userId';
          _service.subscribe(destination: topic, onMessage: _onDriverEvent);
        }
        break;

      case 'CUSTOMER':
        break;

      default:
        logger.w('[RT] Unknown user role: $userRole');
    }
  }

  void _onRestaurantEvent(String body) {
    try {
      final event = OrderEvent.fromJson(jsonDecode(body));
      RestaurantEventHandler().handle(event);
    } catch (e) {
      logger.e('[RT] Restaurant event parse error: $e');
    }
  }

  void _onDriverEvent(String body) {
    try {
      final event = DriverDeliveryEvent.fromJson(jsonDecode(body));
      DriverEventHandler().handle(event);
    } catch (e, stack) {
      logger.e('[RT] Driver event parse error', error: e, stackTrace: stack);
    }
  }
}
