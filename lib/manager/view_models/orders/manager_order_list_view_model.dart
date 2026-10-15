import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/models/domain/order.dart';
import 'package:dineroo_mobile/manager/repositories/manager_order_repository.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/enums/order_status.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:provider/provider.dart';

class ManagerOrderListViewModel extends ChangeNotifier {
  final ManagerOrderRepository _repository;

  ManagerOrderListViewModel(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Order> _orders = [];
  List<Order> get orders => _orders;

  final Map<String, DateTime> _recentStatusUpdateDates = {};

  Future<void> fetchOrdersByRestaurant(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final currentUser = context.read<CurrentUserViewModel>().currentUser;
      final restaurantId = currentUser?.organization?.id;
      if (restaurantId == null) return;

      _orders = await _repository.fetchOrdersByRestaurant(restaurantId);
      final fetchedOrderIds =
          _orders.map((order) => order.id.toString()).toSet();
      _recentStatusUpdateDates.removeWhere(
        (orderId, _) => !fetchedOrderIds.contains(orderId),
      );
    } catch (e, stack) {
      logger.e('Manager - Failed to fetch orders', error: e, stackTrace: stack);
      _orders = [];
      _recentStatusUpdateDates.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void applyLocalStatusUpdate({
    required String orderId,
    required OrderStatus status,
  }) {
    final now = DateTime.now();
    final orderIndex = _orders.indexWhere(
      (order) => order.id.toString() == orderId,
    );

    if (orderIndex != -1) {
      _orders[orderIndex] = _orders[orderIndex].copyWith(
        status: status,
        lastModifiedDate: now,
      );
    }

    _recentStatusUpdateDates[orderId] = now;
    notifyListeners();
  }

  DateTime effectiveLastModifiedDate(Order order) {
    return _recentStatusUpdateDates[order.id.toString()] ??
        order.lastModifiedDate;
  }
}
