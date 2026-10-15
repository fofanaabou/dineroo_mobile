import 'package:dineroo_mobile/shared/models/domain/order.dart';
import 'package:flutter/material.dart';
import 'package:dineroo_mobile/customer/repositories/order_repository.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';

class OrderViewModel extends ChangeNotifier {
  final OrderRepository _repository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  OrderViewModel(this._repository);

  Future<Order> createOrder(Map<String, dynamic> orderData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final order = await _repository.createOrder(orderData);
      return order;
    } catch (e, stack) {
      logger.e('Order creation failed', error: e, stackTrace: stack);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
