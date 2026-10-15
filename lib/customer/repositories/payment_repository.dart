import 'package:dineroo_mobile/customer/services/payment/payment_service.dart';
import 'package:dineroo_mobile/customer/models/domain/payment.dart';
import 'package:dineroo_mobile/customer/models/dto/payment_request_dto.dart';
import 'package:dineroo_mobile/customer/models/dto/payment_response_dto.dart';

class PaymentRepository {
  final PaymentService _service;
  PaymentRepository({required PaymentService service}) : _service = service;

  Future<Payment> createPayment({
    required String customerId,
    required String orderId,
    required double amount,
    String? paymentMethod,
    double walletAmount = 0,
  }) async {
    try {
      final payload = PaymentRequestDto(
        customerId: customerId,
        orderId: orderId,
        amount: amount,
        paymentMethod: paymentMethod,
        walletAmount: walletAmount,
      );
      final json = await _service.createPayment(payload.toJson());
      final dto = PaymentResponseDto.fromJson(json);
      final payment = dto.toDomain();
      return payment;
    } catch (e) {
      rethrow;
    }
  }

  Future<Payment> getPayment(String id) async {
    final json = await _service.getPayment(id);
    final dto = PaymentResponseDto.fromJson(json);
    final payment = dto.toDomain();
    return payment;
  }
}
