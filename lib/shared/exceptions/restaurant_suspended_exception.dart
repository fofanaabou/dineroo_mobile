import 'package:dineroo_mobile/shared/enums/api_error_code.dart';
import 'package:dineroo_mobile/shared/enums/http_status_code.dart';

class RestaurantSuspendedException implements Exception {
  static const String message =
      'Votre restaurant est suspendu. Contactez le support Dineroo.';

  const RestaurantSuspendedException();

  static bool matchesResponse(int? statusCode, dynamic body) {
    if (statusCode != HttpStatusCode.forbidden.code) return false;
    if (body is! Map) return false;
    return ApiErrorCode.restaurantSuspended.matches(body['type']?.toString());
  }

  @override
  String toString() => message;
}
