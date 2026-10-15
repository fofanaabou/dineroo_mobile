import 'package:dineroo_mobile/shared/common/widgets/app_pdf_viewer.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_scaffold.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_snackbar.dart';
import 'package:dineroo_mobile/customer/enums/payment_gateway_result.dart';
import 'package:dineroo_mobile/customer/helpers/payment_receipt_downloader.dart';

class PaymentView extends StatefulWidget {
  final String paymentId;
  final String paymentToken;
  final String paymentGatewayUrlTemplate;
  final String? successUrlContains;
  final String? failureUrlContains;

  const PaymentView({
    super.key,
    required this.paymentId,
    required this.paymentToken,
    required this.paymentGatewayUrlTemplate,
    this.successUrlContains,
    this.failureUrlContains,
  });

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  late final WebViewController _controller;

  bool isLoading = true;
  bool _isClosing = false;
  bool _isDownloadingReceipt = false;

  static const Set<String> _returnHosts = {
    'dineroo.africa',
    'www.dineroo.africa',
  };

  String get _initialUrl => widget.paymentGatewayUrlTemplate.replaceAll(
    '{token}',
    widget.paymentToken,
  );

  Future<void> _closeOnce(PaymentGatewayResult result) async {
    if (_isClosing) return;
    _isClosing = true;
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  PaymentGatewayResult? _gatewayResultFromUrl(String? url) {
    final uri = Uri.tryParse(url ?? '');
    final host = (uri?.host ?? '').toLowerCase();
    if (!_returnHosts.contains(host)) return null;

    // Djomy redirects to dineroo.africa with ?status=SUCCESS|FAILED
    final status = (uri?.queryParameters['status'] ?? '').trim().toUpperCase();
    if (status.isEmpty) return PaymentGatewayResult.noStatus;
    if (status == 'SUCCESS') return PaymentGatewayResult.success;
    if (status == 'FAILED') return PaymentGatewayResult.failed;
    if (status == 'CANCELED' || status == 'CANCELLED') {
      return PaymentGatewayResult.canceled;
    }
    return PaymentGatewayResult.canceled;
  }

  bool _isDjomyHost(String host) {
    return host == 'djomy.africa' || host.endsWith('.djomy.africa');
  }

  bool _preventWebViewNavigation(String url) {
    final uri = Uri.tryParse(url);
    final scheme = (uri?.scheme ?? '').toLowerCase();
    if (uri == null || scheme.isEmpty) return true;
    if (scheme != 'http' && scheme != 'https') return true;

    final host = uri.host.toLowerCase();
    final path = uri.path.trim();
    final isDjomyHome = _isDjomyHost(host) && (path.isEmpty || path == '/');
    return isDjomyHome;
  }

  Future<void> _preventDjomyHomeNavigation() async {
    try {
      await _controller.runJavaScript('''
        (function () {
          if (window.__dinerooDjomyGuardInstalled) return;
          window.__dinerooDjomyGuardInstalled = true;

          function isDjomyHomeLink(link) {
            var url = new URL(link.href, window.location.href);
            return url.pathname === '/'
              && (url.hostname === 'djomy.africa' || url.hostname.endsWith('.djomy.africa'));
          }

          document.addEventListener('click', function (event) {
            var link = event.target.closest && event.target.closest('a[href]');
            if (!link || !isDjomyHomeLink(link)) return;
            event.preventDefault();
            event.stopImmediatePropagation();
          }, true);
        })();
      ''');
    } catch (e, stack) {
      logger.e(
        '[PAYMENT][WEBVIEW] failed to install Djomy guard',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> _openPaymentReceiptViewer({String? title}) async {
    if (_isDownloadingReceipt) return;
    setState(() => _isDownloadingReceipt = true);

    try {
      final currentUrl = await _controller.currentUrl();
      if (currentUrl == null || currentUrl.trim().isEmpty) {
        throw Exception('Cannot read current url');
      }

      final filePath =
          await PaymentReceiptDownloader.downloadReceiptFromDjomyPageUrl(
            currentUrl,
            fileName: 'djomy-receipt.pdf',
          );

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (_) => AppPdfViewer(
                title: title ?? 'Reçu de paiement',
                filePath: filePath,
              ),
        ),
      );
    } catch (e, stack) {
      logger.e('[PAYMENT][RECEIPT] error', error: e, stackTrace: stack);

      if (!mounted) return;
      AppSnackbar.error(
        context,
        'Impossible de recupérer le reçu de paiement. Veuillez réessayer !',
        bottomMargin: 80,
      );
    } finally {
      if (mounted) setState(() => _isDownloadingReceipt = false);
    }
  }

  @override
  void initState() {
    super.initState();

    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.white)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (_) {
                if (mounted) setState(() => isLoading = true);
              },
              onPageFinished: (_) {
                if (mounted) setState(() => isLoading = false);
                _preventDjomyHomeNavigation();
              },
              onWebResourceError: (error) {
                logger.e(
                  '[PAYMENT][WEBVIEW] resourceError '
                  'code=${error.errorCode} '
                  'type=${error.errorType} '
                  'desc=${error.description} '
                  'url=${error.url}',
                );
              },
              onNavigationRequest: (request) async {
                if (_isClosing) return NavigationDecision.prevent;
                final url = request.url;

                if (PaymentReceiptDownloader.isBlobUrl(url)) {
                  await _openPaymentReceiptViewer();
                  return NavigationDecision.prevent;
                }
                final result = _gatewayResultFromUrl(url);
                if (result != null) {
                  _closeOnce(result);
                  return NavigationDecision.prevent;
                }

                if (_preventWebViewNavigation(url)) {
                  return NavigationDecision.prevent;
                }

                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(_initialUrl));
  }

  Future<void> _handleBack() async {
    if (_isClosing) return;

    final currentUrl = await _controller.currentUrl();
    final result = _gatewayResultFromUrl(currentUrl);
    if (result != null) {
      await _closeOnce(result);
      return;
    }

    await _closeOnce(PaymentGatewayResult.canceled);
  }

  @override
  Widget build(BuildContext context) {
    final showLoader = isLoading || _isDownloadingReceipt;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack();
      },
      child: AppScaffold(
        title: 'Paiement',
        showBack: true,
        onPressed: _handleBack,
        showCartIcon: false,
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (showLoader)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.white,
                  child: Center(child: AppLoader()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
