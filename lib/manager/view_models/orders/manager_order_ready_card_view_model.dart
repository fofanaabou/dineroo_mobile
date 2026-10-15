import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/models/domain/order_details.dart';
import 'package:dineroo_mobile/shared/repositories/order_details_repository.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';

class ManagerOrderReadyCardViewModel extends ChangeNotifier {
  final OrderDetailsRepository _repository;

  ManagerOrderReadyCardViewModel(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  OrderDetails? _orderDetails;
  OrderDetails? get orderDetails => _orderDetails;

  Future<void> init(String orderId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _orderDetails = await _repository.fetchOrderDetails(orderId);
    } catch (e, stack) {
      logger.e(
        'Failed to fetch ready card order-details',
        error: e,
        stackTrace: stack,
      );
      _orderDetails = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
