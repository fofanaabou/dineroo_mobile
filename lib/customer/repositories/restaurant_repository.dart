import 'package:dineroo_mobile/shared/models/domain/pagination_info.dart';
import 'package:dineroo_mobile/shared/models/domain/pagination_params.dart';
import 'package:dineroo_mobile/shared/exceptions/restaurant_unavailable_exception.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/customer/models/domain/restaurant_page.dart';
import 'package:dineroo_mobile/customer/models/domain/restaurant_detail.dart';
import 'package:dineroo_mobile/customer/models/dto/restaurant_dto.dart';
import 'package:dineroo_mobile/customer/models/dto/restaurant_detail_dto.dart';
import 'package:dineroo_mobile/customer/services/restaurant/restaurant_list_service.dart';
import 'package:dineroo_mobile/customer/services/restaurant/restaurant_service.dart';

class RestaurantRepository {
  final RestaurantService _service;
  final RestaurantListService _listService;

  RestaurantRepository({
    required RestaurantService service,
    required RestaurantListService listService,
  }) : _service = service,
       _listService = listService;

  Future<RestaurantPage> getRestaurants(
    PaginationParams params, {
    double? lat,
    double? lon,
  }) async {
    try {
      final data = await _listService.fetchRestaurants(
        params,
        lat: lat,
        lon: lon,
      );
      final items =
          (data['items'] as List)
              .map((e) => RestaurantDto.fromJson(e).toDomain())
              .toList();
      final pageInfo = PaginationInfo.fromJson(data['page']);
      return RestaurantPage(items: items, pageInfo: pageInfo);
    } catch (e, stack) {
      logger.e('Failed to load restaurants', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<RestaurantDetail> getRestaurant(String id) async {
    try {
      final json = await _service.fetchRestaurant(id);
      final dto = RestaurantDetailDto.fromJson(json);
      return dto.toDomain();
    } on RestaurantUnavailableException {
      rethrow;
    } catch (e, stack) {
      logger.e('Failed to load restaurant detail', error: e, stackTrace: stack);
      throw Exception('Failed to load restaurant detail');
    }
  }

  Future<bool> restaurantIsOpen(String id) async {
    try {
      return await _service.restaurantIsOpen(id);
    } catch (e, stack) {
      logger.e(
        "Failed to check restaurant open status",
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }
}
