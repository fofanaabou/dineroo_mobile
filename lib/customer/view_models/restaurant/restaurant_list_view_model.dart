import 'package:hive/hive.dart';
import 'package:dineroo_mobile/shared/models/domain/pagination_info.dart';
import 'package:dineroo_mobile/shared/models/domain/pagination_params.dart';
import 'package:flutter/foundation.dart';
import 'package:dineroo_mobile/customer/models/domain/restaurant.dart';
import 'package:dineroo_mobile/customer/repositories/restaurant_repository.dart';
import 'package:dineroo_mobile/shared/view_models/location/location_view_model.dart';

const int maxRecentSearches = 5;

class RestaurantListViewModel extends ChangeNotifier {
  final RestaurantRepository repository;
  final LocationViewModel locationViewModel;

  List<Restaurant> restaurants = [];
  bool isLoading = false;
  String? error;
  PaginationInfo? paginationInfo;
  List<String> recentSearches = [];

  PaginationParams _params = const PaginationParams();
  final _recentBox = Hive.box<String>('recentSearches');
  String? currentSearch;

  RestaurantListViewModel(this.repository, this.locationViewModel) {
    recentSearches = _recentBox.values.toList().reversed.toList();
  }

  Future<void> fetchRestaurants({bool refresh = false}) async {
    if (refresh) {
      _params = _params.copyWith(page: 1);
      restaurants.clear();
    }

    isLoading = true;
    notifyListeners();

    try {
      final position = locationViewModel.userPosition;
      final lat = position?.latitude;
      final lon = position?.longitude;

      final page = await repository.getRestaurants(_params, lat: lat, lon: lon);
      if (refresh) {
        restaurants = page.items;
      } else {
        restaurants.addAll(page.items);
      }
      paginationInfo = page.pageInfo;
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool get canLoadMore =>
      paginationInfo != null && _params.page < paginationInfo!.totalPages;

  Future<void> loadMore() async {
    if (!canLoadMore) return;
    _params = _params.copyWith(page: _params.page + 1);
    await fetchRestaurants();
  }

  Future<void> searchRestaurants(String query) async {
    currentSearch = query.isNotEmpty ? query : null;
    _params = _params.copyWith(page: 1, search: currentSearch);
    if (query.isNotEmpty) _saveSearch(query);
    restaurants.clear();
    await fetchRestaurants(refresh: true);
  }

  Future<void> resetSearch() async {
    currentSearch = null;
    _params = _params.copyWith(page: 1, search: '');
    restaurants.clear();
    await fetchRestaurants(refresh: true);
  }

  void _saveSearch(String query) {
    final trimmed = query.trim();
    final lowerTrimmed = trimmed.toLowerCase();
    final alreadyExists = _recentBox.values.any(
      (r) => r.toLowerCase() == lowerTrimmed,
    );
    final isSubOfLast = _recentBox.values.any(
      (r) => r.toLowerCase().contains(lowerTrimmed),
    );
    if (alreadyExists || isSubOfLast) return;

    // Remove shorter searches contained in the new
    final hasIncludedShorter =
        _recentBox.values
            .where((r) => lowerTrimmed.contains(r.toLowerCase()))
            .toList();

    for (final old in hasIncludedShorter) {
      final index = _recentBox.values.toList().indexOf(old);
      if (index != -1) {
        _recentBox.deleteAt(index);
      }
    }

    _recentBox.add(trimmed);
    recentSearches = _recentBox.values.toList().reversed.toList();

    if (recentSearches.length > maxRecentSearches) {
      final extraCount = recentSearches.length - maxRecentSearches;
      for (int i = 0; i < extraCount; i++) {
        _recentBox.deleteAt(0);
      }
      recentSearches = _recentBox.values.toList().reversed.toList();
    }

    notifyListeners();
  }

  void clearRecentSearches() {
    _recentBox.clear();
    recentSearches.clear();
    notifyListeners();
  }
}
