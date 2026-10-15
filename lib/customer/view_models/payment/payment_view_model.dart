import 'package:flutter/material.dart';
import 'package:dineroo_mobile/customer/repositories/payment_repository.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/customer/enums/payment_status.dart';
import 'package:dineroo_mobile/customer/models/domain/payment.dart';

class PaymentViewModel extends ChangeNotifier {
  final PaymentRepository _repo;

  PaymentViewModel(this._repo);

  Payment? lastPayment;
  PaymentStatus lastStatus = PaymentStatus.unknown;
  String? error;
  bool isLoading = false;

  Future<Payment> createPayment({
    required String customerId,
    required String orderId,
    required double amount,
    String? paymentMethod,
    double walletAmount = 0,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final payment = await _repo.createPayment(
        customerId: customerId,
        orderId: orderId,
        amount: amount,
        paymentMethod: paymentMethod,
        walletAmount: walletAmount,
      );
      lastPayment = payment;
      lastStatus = payment.status;
      return payment;
    } catch (e, stack) {
      error = e.toString();
      logger.e('[PAYMENT][VM] create failed', error: e, stackTrace: stack);
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Payment?> refresh(String paymentId) async {
    try {
      final payment = await _repo.getPayment(paymentId);
      lastPayment = payment;
      lastStatus = payment.status;
      error = null;

      notifyListeners();
      return payment;
    } catch (e, stack) {
      error = e.toString();
      logger.e('[PAYMENT][VM] refresh failed', error: e, stackTrace: stack);
      notifyListeners();
      return null;
    }
  }
}
