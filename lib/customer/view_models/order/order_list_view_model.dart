import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/models/domain/order.dart';
import 'package:dineroo_mobile/customer/repositories/order_repository.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/models/domain/order_event.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';

class OrderListViewModel extends ChangeNotifier {
  final OrderRepository _repository;
  final CurrentUserViewModel _currentUserViewModel;
  bool _disposed = false;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Order> _orders = [];
  List<Order> get orders => _orders;

  OrderListViewModel(this._repository, this._currentUserViewModel);

  bool get hasActiveOrder => _orders.any((o) => o.status.isOngoing);

  Future<void> fetchOrders() async {
    _isLoading = true;
    _safeNotifyListeners();

    try {
      final currentUser = _currentUserViewModel.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      _orders = await _repository.fetchOrders(currentUser.id);
    } catch (e, stack) {
      logger.e('Failed to fetch orders', error: e, stackTrace: stack);
      _orders = [];
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  void updateOrderStatusFromRealtime(OrderEvent event) {
    final index = _orders.indexWhere(
      (o) => o.id.toString() == event.orderId.toString(),
    );

    if (index == -1) return;

    _orders[index] = _orders[index].copyWith(status: event.statusEnum);

    _safeNotifyListeners();
  }

  void upsertOrder(Order order) {
    final index = _orders.indexWhere(
      (o) => o.id.toString() == order.id.toString(),
    );

    if (index == -1) {
      _orders.insert(0, order);
    } else {
      _orders[index] = order;
    }

    _safeNotifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (_disposed) {
      return;
    }

    notifyListeners();
  }
}
