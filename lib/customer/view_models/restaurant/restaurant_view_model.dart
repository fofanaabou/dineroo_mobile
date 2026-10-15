import 'package:dineroo_mobile/shared/exceptions/restaurant_unavailable_exception.dart';
import 'package:dineroo_mobile/customer/models/domain/restaurant_open_status_cache.dart';
import 'package:dineroo_mobile/shared/common/helpers/opening_hours_helper.dart';
import 'package:flutter/material.dart';
import '../../models/domain/restaurant_detail.dart';
import '../../repositories/restaurant_repository.dart';

class RestaurantViewModel extends ChangeNotifier {
  final RestaurantRepository _repository;

  RestaurantViewModel(this._repository);

  RestaurantDetail? _restaurant;
  bool isLoading = true;
  String? error;
  bool isUnavailable = false;

  RestaurantDetail? get restaurant => _restaurant;

  final Map<String, RestaurantOpenStatusCache> _openStatusCache = {};
  static const Duration cacheTTL = Duration(seconds: 60);

  Future<void> fetch(String id) async {
    isLoading = true;
    notifyListeners();

    try {
      _restaurant = await _repository.getRestaurant(id);
      error = null;
      isUnavailable = false;

      final isOpen = OpeningHoursHelper.restaurantIsOpen(
        _restaurant!.openingHours,
      );
      _openStatusCache[id] = RestaurantOpenStatusCache(isOpen, DateTime.now());
    } on RestaurantUnavailableException catch (e) {
      error = e.toString();
      isUnavailable = true;
      _openStatusCache[id] = RestaurantOpenStatusCache(false, DateTime.now());
    } catch (e) {
      error = e.toString();
      isUnavailable = false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> restaurantIsOpen(String restaurantId) async {
    final cache = _openStatusCache[restaurantId];
    if (cache != null && cache.isValid(cacheTTL)) {
      return cache.isOpen;
    }
    return await refreshRestaurantOpenStatus(restaurantId);
  }

  Future<bool> refreshRestaurantOpenStatus(String restaurantId) async {
    try {
      final isOpen = await _repository.restaurantIsOpen(restaurantId);
      _openStatusCache[restaurantId] = RestaurantOpenStatusCache(
        isOpen,
        DateTime.now(),
      );
      notifyListeners();
      return isOpen;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
