@TestOn('vm')
library;

import 'package:dineroo_mobile/customer/services/wallet/wallet_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

Dio _dioCapturing(void Function(RequestOptions options) onRequest) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        onRequest(options);
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {'balance': 0},
          ),
        );
      },
    ),
  );
  return dio;
}

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.test');
  });

  group('WalletService on a native platform', () {
    test('requests the customer wallet endpoint', () async {
      late RequestOptions sent;
      final service = WalletService(dio: _dioCapturing((o) => sent = o));

      final wallet = await service.getWallet('customer-1');

      expect(sent.method, 'GET');
      expect(sent.uri.path, '/v1/wallets/customers/customer-1');
      expect(wallet, {'balance': 0});
    });

    test('keeps asking intermediaries not to cache the wallet', () async {
      late RequestOptions sent;
      final service = WalletService(dio: _dioCapturing((o) => sent = o));

      await service.getWallet('customer-1');

      expect(sent.headers['Cache-Control'], 'no-cache');
    });
  });
}
