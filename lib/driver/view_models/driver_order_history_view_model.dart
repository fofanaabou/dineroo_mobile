import 'package:flutter/material.dart';
import 'package:dineroo_mobile/driver/enums/delivery_status.dart';
import 'package:dineroo_mobile/driver/models/domain/driver_delivery.dart';
import 'package:dineroo_mobile/driver/repositories/driver_delivery_repository.dart';
import 'package:dineroo_mobile/driver/repositories/driver_order_repository.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/models/domain/order.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';

class DriverOrderHistoryItem {
  final Order order;
  final DriverDelivery delivery;

  const DriverOrderHistoryItem({required this.order, required this.delivery});
}

class DriverOrderHistoryViewModel extends ChangeNotifier {
  final DriverDeliveryRepository _deliveryRepository;
  final DriverOrderRepository _orderRepository;
  final CurrentUserViewModel _currentUserViewModel;

  DriverOrderHistoryViewModel(
    this._deliveryRepository,
    this._orderRepository,
    this._currentUserViewModel,
  );

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasError = false;
  bool get hasError => _hasError;

  int _failedOrdersCount = 0;
  int get failedOrdersCount => _failedOrdersCount;
  bool get hasPartialError => _failedOrdersCount > 0;

  List<DriverOrderHistoryItem> _items = [];
  List<DriverOrderHistoryItem> get items => _items;
  List<Order> get orders => _items.map((item) => item.order).toList();

  DriverOrderHistoryItem? itemForOrder(Order order) {
    try {
      return _items.firstWhere(
        (item) => item.order.id.toString() == order.id.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchOrders() async {
    final driverId = _currentUserViewModel.currentUser?.id;
    if (driverId == null || driverId.isEmpty) {
      _items = [];
      _hasError = true;
      _failedOrdersCount = 0;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _hasError = false;
    _failedOrdersCount = 0;
    notifyListeners();

    try {
      final deliveries = await _deliveryRepository.fetchDeliveriesByDriverId(
        driverId: driverId,
        statuses: [
          DeliveryStatus.delivered.apiValue,
          DeliveryStatus.canceled.apiValue,
        ],
      );

      final orderIds =
          deliveries
              .map((delivery) => delivery.orderId)
              .where((orderId) => orderId.isNotEmpty)
              .toSet()
              .toList();

      final orders = await _orderRepository.fetchOrdersByIds(orderIds);

      final loadedOrderIds = orders.map((order) => order.id.toString()).toSet();
      for (final orderId in orderIds) {
        if (loadedOrderIds.contains(orderId)) continue;

        _failedOrdersCount++;
        logger.w(
          '[DriverOrderHistory] Order ignored because it was not returned by batch: $orderId',
        );
      }

      final deliveriesByOrderId = {
        for (final delivery in deliveries) delivery.orderId: delivery,
      };

      final historyItems = <DriverOrderHistoryItem>[];
      for (final order in orders) {
        final delivery = deliveriesByOrderId[order.id.toString()];
        if (delivery == null) {
          _failedOrdersCount++;
          logger.w(
            '[DriverOrderHistory] Order ignored because matching delivery is missing: ${order.id}',
          );
          continue;
        }

        historyItems.add(
          DriverOrderHistoryItem(order: order, delivery: delivery),
        );
      }

      historyItems.sort((a, b) {
        return b.order.createdDate.compareTo(a.order.createdDate);
      });

      _items = historyItems;
    } catch (e, stack) {
      logger.e(
        '[DriverOrderHistory] Failed to fetch driver order history',
        error: e,
        stackTrace: stack,
      );
      _items = [];
      _hasError = true;
      _failedOrdersCount = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
