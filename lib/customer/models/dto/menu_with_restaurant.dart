import 'package:dineroo_mobile/customer/models/domain/menu_detail.dart';
import 'package:dineroo_mobile/customer/models/domain/restaurant.dart';

class MenuWithRestaurant {
  final MenuDetail menuDetail;
  final Restaurant restaurant;

  MenuWithRestaurant({required this.menuDetail, required this.restaurant});
}
