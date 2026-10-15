import 'package:dineroo_mobile/customer/models/domain/restaurant.dart';
import 'package:dineroo_mobile/shared/models/domain/pagination_info.dart';

class RestaurantPage {
  final List<Restaurant> items;
  final PaginationInfo pageInfo;

  RestaurantPage({required this.items, required this.pageInfo});
}
