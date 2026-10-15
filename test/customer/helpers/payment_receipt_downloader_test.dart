import 'package:dineroo_mobile/customer/helpers/payment_receipt_downloader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaymentReceiptDownloader', () {
    group('isBlobUrl', () {
      test('returns true for blob URLs', () {
        expect(PaymentReceiptDownloader.isBlobUrl('blob:https://example.com'), isTrue);
        expect(PaymentReceiptDownloader.isBlobUrl('BLOB:https://example.com'), isTrue);
      });
      test('returns false for non-blob URLs', () {
        expect(PaymentReceiptDownloader.isBlobUrl('https://example.com'), isFalse);
        expect(PaymentReceiptDownloader.isBlobUrl(''), isFalse);
      });
    });
    group('extractPaymentTokenFromDjomyUrl', () {
      test('extracts token from valid djomy URL', () {
        final token = PaymentReceiptDownloader.extractPaymentTokenFromDjomyUrl(
          'https://sandbox.djomy.africa/p/aaa',
        );
        expect(token, 'aaa');
      });
      test('returns null for URL without p segment', () {
        expect(
          PaymentReceiptDownloader.extractPaymentTokenFromDjomyUrl(
            'https://sandbox.djomy.africa/other/aaa',
          ),
          isNull,
        );
      });
      test('returns null when p is the last segment', () {
        expect(
          PaymentReceiptDownloader.extractPaymentTokenFromDjomyUrl(
            'https://sandbox.djomy.africa/p',
          ),
          isNull,
        );
      });
      test('returns null for invalid URL', () {
        expect(PaymentReceiptDownloader.extractPaymentTokenFromDjomyUrl(''), isNull);
      });
      test('returns null for whitespace-only token', () {
        expect(
          PaymentReceiptDownloader.extractPaymentTokenFromDjomyUrl(
            'https://sandbox.djomy.africa/p/   ',
          ),
          isNull,
        );
      });
    });
    group('downloadReceiptFromDjomyPageUrl', () {
      test('throws when token cannot be extracted', () async {
        expect(
          () => PaymentReceiptDownloader.downloadReceiptFromDjomyPageUrl('invalid-url'),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
