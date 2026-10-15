import 'package:dineroo_mobile/customer/enums/payment_status.dart';
import 'package:dineroo_mobile/customer/repositories/payment_repository.dart';
import 'package:dineroo_mobile/customer/services/payment/payment_service.dart';
import 'package:dineroo_mobile/customer/view_models/payment/payment_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaymentViewModel', () {
    late _FakePaymentService service;
    late PaymentViewModel viewModel;

    setUp(() {
      service = _FakePaymentService();
      viewModel = PaymentViewModel(PaymentRepository(service: service));
    });

    test('creates a payment and stores the last status', () async {
      final states = <bool>[];
      viewModel.addListener(() => states.add(viewModel.isLoading));

      final payment = await viewModel.createPayment(
        customerId: 'customer-1',
        orderId: 'order-1',
        amount: 12500,
      );

      expect(service.createdPayload, {
        'customerId': 'customer-1',
        'orderId': 'order-1',
        'amount': 12500.0,
        'walletAmount': 0.0,
      });
      expect(payment.id, 'payment-1');
      expect(viewModel.lastPayment, payment);
      expect(viewModel.lastStatus, PaymentStatus.pending);
      expect(viewModel.error, isNull);
      expect(states, [true, false]);
    });

    test('forwards wallet split fields to payment repository', () async {
      await viewModel.createPayment(
        customerId: 'customer-1',
        orderId: 'order-1',
        amount: 35000,
        paymentMethod: 'WALLET',
        walletAmount: 12000,
      );

      expect(service.createdPayload, {
        'customerId': 'customer-1',
        'orderId': 'order-1',
        'amount': 35000.0,
        'paymentMethod': 'WALLET',
        'walletAmount': 12000.0,
      });
    });

    test('keeps an error when payment creation fails', () async {
      service.createException = Exception('backend down');

      await expectLater(
        () => viewModel.createPayment(
          customerId: 'customer-1',
          orderId: 'order-1',
          amount: 12500,
        ),
        throwsException,
      );

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.error, contains('backend down'));
    });

    test('refreshes payment status and tolerates refresh failures', () async {
      service.paymentStatus = 'COMPLETED';

      final payment = await viewModel.refresh('payment-1');

      expect(payment?.status, PaymentStatus.success);
      expect(viewModel.lastStatus, PaymentStatus.success);
      expect(viewModel.error, isNull);

      service.refreshException = Exception('not found');
      final failed = await viewModel.refresh('missing');

      expect(failed, isNull);
      expect(viewModel.error, contains('not found'));
    });
  });
}

class _FakePaymentService extends PaymentService {
  Map<String, dynamic>? createdPayload;
  Object? createException;
  Object? refreshException;
  String paymentStatus = 'PENDING';

  @override
  Future<Map<String, dynamic>> createPayment(
    Map<String, dynamic> payload,
  ) async {
    final exception = createException;
    if (exception != null) throw exception;
    createdPayload = payload;
    return {
      'id': 'payment-1',
      'customerId': payload['customerId'],
      'orderId': payload['orderId'],
      'amount': payload['amount'],
      'currency': 'GNF',
      'status': 'PENDING',
      'paymentToken': 'token-1',
    };
  }

  @override
  Future<Map<String, dynamic>> getPayment(String id) async {
    final exception = refreshException;
    if (exception != null) throw exception;
    return {
      'id': id,
      'customerId': 'customer-1',
      'orderId': 'order-1',
      'amount': 12500,
      'currency': 'GNF',
      'status': paymentStatus,
      'paymentToken': 'token-1',
    };
  }
}
