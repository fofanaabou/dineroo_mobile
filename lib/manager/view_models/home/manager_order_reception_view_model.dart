import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:flutter/material.dart';
import 'package:dineroo_mobile/manager/repositories/manager_order_repository.dart';
import 'package:dineroo_mobile/shared/models/domain/order.dart';
import 'package:dineroo_mobile/shared/models/domain/order_event.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/enums/order_status.dart';
import 'package:provider/provider.dart';

class ManagerOrderReceptionViewModel extends ChangeNotifier {
  final ManagerOrderRepository _repository;

  ManagerOrderReceptionViewModel({required ManagerOrderRepository repository})
    : _repository = repository;

  final List<Order> _allOrders = [];
  List<Order> get allOrders => _allOrders;

  final List<Order> _orders = [];
  List<Order> get orders => _orders;

  int get newOrdersCount =>
      _allOrders.where((o) => o.status == OrderStatus.paymentConfirmed).length;

  int get readyOrdersCount =>
      _allOrders.where((o) => o.status == OrderStatus.readyForPickup).length;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _isSyncing = false;

  Future<void> syncWithServer(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final currentUser = context.read<CurrentUserViewModel>().currentUser;
      final restaurantId = currentUser?.organization?.id;
      if (restaurantId == null) {
        logger.w('[SYNC] No restaurants associated with the current manager');
        _isLoading = false;
        notifyListeners();
        return;
      }

      final fetched = await _repository.fetchOrdersByRestaurant(restaurantId);
      final pendingPaymentOnly = fetched
          .where((o) => o.status == OrderStatus.paymentConfirmed)
          .toList();
      _allOrders
        ..clear()
        ..addAll(fetched);
      _orders
        ..clear()
        ..addAll(pendingPaymentOnly);
    } catch (e, stack) {
      logger.e(
        '[SYNC] Error while synchronizing orders',
        error: e,
        stackTrace: stack,
      );
      if (_allOrders.isEmpty) {
        logger.w('[SYNC] Orders list is empty after failed sync');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> handleRealtimeOrder(
    OrderEvent event,
    BuildContext context,
  ) async {
    logger.i('[RT] Event ${event.status} received for ${event.orderId}');

    if (_isSyncing) return;

    _isSyncing = true;
    try {
      await syncWithServer(context);
    } catch (e, stack) {
      logger.e('[RT] Error during sync', error: e, stackTrace: stack);
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> acceptOrder(String restaurantId, String orderId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.acceptOrder(restaurantId, orderId);
      removeOrder(orderId);
      return true;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> rejectOrder(String restaurantId, String orderId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.rejectOrder(restaurantId, orderId);
      removeOrder(orderId);
      return true;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStatus({
    required String restaurantId,
    required String orderId,
    required String status,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.updateOrderStatus(
        restaurantId: restaurantId,
        orderId: orderId,
        status: status,
      );
      return true;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> validatePickupOtp({
    required String orderId,
    required String code,
    String? validatedBy,
    required String restaurantId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      return await _repository.validatePickupOtp(
        orderId: orderId,
        code: code,
        validatedBy: validatedBy,
        restaurantId: restaurantId,
      );
    } catch (e) {
      final message = e.toString();
      if (message.contains('Code de récupération invalide.')) {
        return null;
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void removeOrder(String id) {
    _orders.removeWhere((order) => order.id.toString() == id);
    _allOrders.removeWhere((order) => order.id.toString() == id);
    notifyListeners();
  }
}
