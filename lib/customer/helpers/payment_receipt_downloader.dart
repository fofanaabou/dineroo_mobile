import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dineroo_mobile/shared/common/network/dio_client.dart';
import 'package:dineroo_mobile/shared/enums/http_status_code.dart';
import 'package:path_provider/path_provider.dart';

class PaymentReceiptDownloader {
  static bool isBlobUrl(String url) =>
      url.trim().toLowerCase().startsWith('blob:');

  static String? extractPaymentTokenFromDjomyUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final segments = uri.pathSegments;
    final pIndex = segments.indexOf('p');
    if (pIndex == -1 || pIndex + 1 >= segments.length) return null;

    final token = segments[pIndex + 1].trim();
    return token.isEmpty ? null : token;
  }

  /// currentDjomyPageUrl ex: https://sandbox.djomy.africa/p/aaa
  /// -> GET https://sandbox.djomy.africa/api/payments/generate-receipt?transactionId=aaa
  /// -> save pdf in temp and return filePath
  static Future<String> downloadReceiptFromDjomyPageUrl(
    String currentDjomyPageUrl, {
    String fileName = 'djomy-receipt.pdf',
  }) async {
    final token = extractPaymentTokenFromDjomyUrl(currentDjomyPageUrl);
    if (token == null) {
      throw Exception('Cannot extract token from url: $currentDjomyPageUrl');
    }

    final pageUri = Uri.parse(currentDjomyPageUrl);
    final receiptUri = Uri(
      scheme: pageUri.scheme,
      host: pageUri.host,
      path: '/api/payments/generate-receipt',
      queryParameters: {'transactionId': token},
    );

    final res = await createPublicDioClient().get<List<int>>(
      receiptUri.toString(),
      options: Options(
        responseType: ResponseType.bytes,
        validateStatus: (_) => true,
      ),
    );
    final statusCode = res.statusCode ?? 0;
    if (statusCode < HttpStatusCode.ok.code ||
        statusCode >= HttpStatusCode.multipleChoices.code) {
      throw Exception('Receipt download failed (code $statusCode)');
    }

    final bytes = res.data;
    if (bytes == null || bytes.isEmpty) {
      throw Exception('Receipt download failed (empty bytes)');
    }

    final dir = await getTemporaryDirectory();
    final safeName = fileName.trim().isEmpty ? 'djomy-receipt.pdf' : fileName;
    final file = File('${dir.path}/$safeName');

    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
