import 'package:dineroo_mobile/shared/enums/api_error_code.dart';
import 'package:dineroo_mobile/shared/enums/http_status_code.dart';

class OrderCreationException implements Exception {
  final int statusCode;
  final String body;
  final String? code;
  final List<String> unavailableItems;
  final List<String> validationErrors;

  OrderCreationException({
    required this.statusCode,
    required this.body,
    this.code,
    this.unavailableItems = const [],
    this.validationErrors = const [],
  });

  bool get isRestaurantUnavailable =>
      statusCode == HttpStatusCode.conflict.code &&
      ApiErrorCode.restaurantSuspended.matches(code);

  @override
  String toString() => 'OrderCreationException(statusCode: $statusCode)';
}
