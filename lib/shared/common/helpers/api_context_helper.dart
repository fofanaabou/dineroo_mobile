import 'package:dineroo_mobile/shared/enums/user_role.dart';

enum ApiContext { customer, restaurant }

String apiContextQueryValue(ApiContext context) {
  switch (context) {
    case ApiContext.customer:
      return 'CUSTOMER';
    case ApiContext.restaurant:
      return 'RESTAURANT';
  }
}

ApiContext resolveApiContext(UserRole? role) =>
    role == UserRole.restaurantManager
    ? ApiContext.restaurant
    : ApiContext.customer;
