import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/exceptions/restaurant_suspended_exception.dart';
import 'package:dineroo_mobile/shared/models/domain/opening_hours.dart';
import 'package:dineroo_mobile/shared/models/domain/suspension.dart';
import 'package:dineroo_mobile/manager/repositories/manager_restaurant_repository.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';

class ManagerRestaurantViewModel extends ChangeNotifier {
  final ManagerRestaurantRepository repository;
  final CurrentUserViewModel? currentUserViewModel;

  bool isLoading = true;
  bool isSaving = false;
  String? error;

  List<OpeningHours> openingHours = [];

  Suspension? suspension;

  ManagerRestaurantViewModel(this.repository, {this.currentUserViewModel});

  String? get currentRestaurantId =>
      currentUserViewModel?.currentUser?.organization?.id;

  bool get isSuspended => suspension != null;

  Future<void> loadRestaurantState([String? restaurantId]) async {
    final id = restaurantId ?? currentRestaurantId;
    if (id == null || id.isEmpty) {
      isLoading = false;
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      await _fetchRestaurantState(id);
      error = null;
    } catch (e, stack) {
      logger.e('Exception loading restaurant state', error: e, stackTrace: stack);
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Refreshes the state this view model holds without touching [error], so a
  /// caller that already carries a business error can re-read the authoritative
  /// state without that error being replaced by a transport failure.
  Future<void> _fetchRestaurantState(String restaurantId) async {
    final restaurant = await repository.fetchRestaurant(restaurantId);
    openingHours = restaurant.openingHours;
    suspension = restaurant.suspension;
    logger.i('Restaurant $restaurantId state loaded (suspended: $isSuspended)');
  }

  void setDayOpeningHours(String day, List<TimeRange> ranges) {
    final index = openingHours.indexWhere((e) => e.day == day);
    if (index != -1) {
      openingHours[index] = OpeningHours(day: day, timeRanges: ranges);
    } else {
      openingHours.add(OpeningHours(day: day, timeRanges: ranges));
    }
    notifyListeners();
  }

  Future<void> saveOpeningHours(String restaurantId) async {
    isSaving = true;
    notifyListeners();

    try {
      final payload = openingHours
          .map(
            (h) => {
              'day': h.day,
              'timeRanges': h.timeRanges
                  .map((t) => {'start': t.start, 'end': t.end})
                  .toList(),
            },
          )
          .toList();

      await repository.updateOpeningHours(restaurantId, payload);
      error = null;
      logger.i('Opening hours updated successfully for $restaurantId');
    } on RestaurantSuspendedException catch (e) {
      logger.w('Opening hours refused for $restaurantId: restaurant suspended');
      error = e.toString();
      await _refreshAfterSuspensionRefusal(restaurantId);
    } catch (e) {
      logger.e('Error updating opening hours', error: e);
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// Re-reads the authoritative state after the server refused a write. The
  /// suspension error already shown to the manager is the outcome that matters,
  /// so a failing refresh is logged and swallowed rather than reported instead.
  Future<void> _refreshAfterSuspensionRefusal(String restaurantId) async {
    try {
      await _fetchRestaurantState(restaurantId);
    } catch (e, stack) {
      logger.e(
        'Failed to refresh restaurant state after a suspension refusal',
        error: e,
        stackTrace: stack,
      );
    }
  }
}
