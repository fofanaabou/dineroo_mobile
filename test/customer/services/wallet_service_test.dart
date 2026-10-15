import 'package:dio/dio.dart';
import 'package:dineroo_mobile/customer/services/wallet/wallet_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.test');
  });

  group('WalletService', () {
    test('gets wallet by customer id without cache', () async {
      late RequestOptions capturedOptions;
      final service = WalletService(
        dio: _dio((options) {
          capturedOptions = options;
          return _response(options, {
            'id': 'wallet-1',
            'customerId': 'customer-1',
            'balance': 10000,
          });
        }),
      );

      final result = await service.getWallet('customer-1');

      expect(result['id'], 'wallet-1');
      expect(capturedOptions.method, 'GET');
      expect(
        capturedOptions.uri.toString(),
        contains('/wallets/customers/customer-1'),
      );
      expect(capturedOptions.headers['Cache-Control'], 'no-cache');
    });

    test('throws when backend does not return 200', () async {
      final service = WalletService(
        dio: _dio(
          (options) =>
              _response(options, {'message': 'error'}, statusCode: 500),
        ),
      );

      await expectLater(
        () => service.getWallet('customer-1'),
        throwsA(isA<Exception>()),
      );
    });
  });
}

Dio _dio(Response<dynamic> Function(RequestOptions options) responder) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        try {
          handler.resolve(responder(options));
        } catch (error) {
          handler.reject(DioException(requestOptions: options, error: error));
        }
      },
    ),
  );
  return dio;
}

Response<dynamic> _response(
  RequestOptions options,
  Object? data, {
  int statusCode = 200,
}) {
  return Response<dynamic>(
    requestOptions: options,
    statusCode: statusCode,
    data: data,
  );
}
