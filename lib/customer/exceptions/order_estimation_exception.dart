class OrderEstimationException implements Exception {
  final int statusCode;
  final String body;

  OrderEstimationException({required this.statusCode, required this.body});

  @override
  String toString() => 'OrderEstimationException(statusCode: $statusCode)';
}
