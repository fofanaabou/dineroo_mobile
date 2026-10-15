class OrderEstimation {
  final double subtotal;
  final double serviceFee;
  final double deliveryFee;
  final double total;
  final double? djomyFee;

  const OrderEstimation({
    required this.subtotal,
    required this.serviceFee,
    required this.deliveryFee,
    required this.total,
    this.djomyFee,
  });

  factory OrderEstimation.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) => (value as num?)?.toDouble() ?? 0;

    return OrderEstimation(
      subtotal: toDouble(json['subtotal']),
      serviceFee: toDouble(json['serviceFee']),
      deliveryFee: toDouble(json['deliveryFee']),
      total: toDouble(json['total']),
      djomyFee: (json['djomyFee'] as num?)?.toDouble(),
    );
  }
}
