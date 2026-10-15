class DriverDeliveryEvent {
  final String deliveryId;
  final String orderId;
  final String deliveryAddress;
  final String pickupAddress;
  final String restaurantName;
  final double estimatedDeliveryDistance;
  final double deliveryFee;
  final List<String> driverIds;

  DriverDeliveryEvent({
    required this.deliveryId,
    required this.orderId,
    required this.deliveryAddress,
    required this.pickupAddress,
    required this.restaurantName,
    required this.estimatedDeliveryDistance,
    required this.deliveryFee,
    required this.driverIds,
  });

  factory DriverDeliveryEvent.fromJson(Map<String, dynamic> json) {
    return DriverDeliveryEvent(
      deliveryId: (json['deliveryId'] ?? '').toString(),
      orderId: (json['orderId'] ?? '').toString(),
      deliveryAddress: (json['deliveryAddress'] ?? '').toString(),
      pickupAddress: (json['pickupAddress'] ?? '').toString(),
      restaurantName: (json['restaurantName'] ?? '').toString(),
      estimatedDeliveryDistance:
          (json['estimatedDeliveryDistance'] as num?)?.toDouble() ?? 0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0,
      driverIds:
          (json['driverIds'] as List? ?? []).map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'deliveryId': deliveryId,
    'orderId': orderId,
    'deliveryAddress': deliveryAddress,
    'pickupAddress': pickupAddress,
    'restaurantName': restaurantName,
    'estimatedDeliveryDistance': estimatedDeliveryDistance,
    'deliveryFee': deliveryFee,
    'driverIds': driverIds,
  };

  DriverDeliveryEvent copyWith({
    String? deliveryId,
    String? orderId,
    String? deliveryAddress,
    String? pickupAddress,
    String? restaurantName,
    double? estimatedDeliveryDistance,
    double? deliveryFee,
    List<String>? driverIds,
  }) {
    return DriverDeliveryEvent(
      deliveryId: deliveryId ?? this.deliveryId,
      orderId: orderId ?? this.orderId,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      restaurantName: restaurantName ?? this.restaurantName,
      estimatedDeliveryDistance:
          estimatedDeliveryDistance ?? this.estimatedDeliveryDistance,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      driverIds: driverIds ?? this.driverIds,
    );
  }

  @override
  String toString() {
    return 'DriverDeliveryEvent('
        'deliveryId: $deliveryId, '
        'orderId: $orderId, '
        'restaurantName: $restaurantName, '
        'pickupAddress: $pickupAddress, '
        'deliveryAddress: $deliveryAddress, '
        'estimatedDeliveryDistance: $estimatedDeliveryDistance, '
        'deliveryFee: $deliveryFee'
        ')';
  }
}
