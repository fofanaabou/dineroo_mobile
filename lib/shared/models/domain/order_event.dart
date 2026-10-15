import 'package:dineroo_mobile/shared/enums/order_status.dart';

class OrderEvent {
  final String restaurantId;
  final String customerId;
  final String orderId;
  final String status;

  OrderEvent({
    required this.restaurantId,
    required this.customerId,
    required this.orderId,
    required this.status,
  });

  factory OrderEvent.fromJson(Map<String, dynamic> json) {
    return OrderEvent(
      restaurantId: json['restaurantId']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }

  OrderStatus get statusEnum => OrderStatus.fromString(status);

  Map<String, dynamic> toJson() => {
    'restaurantId': restaurantId,
    'customerId': customerId,
    'orderId': orderId,
    'status': status,
  };

  @override
  String toString() {
    return 'OrderEvent(orderId: $orderId, status: $status, customerId: $customerId, restaurantId: $restaurantId)';
  }
}
