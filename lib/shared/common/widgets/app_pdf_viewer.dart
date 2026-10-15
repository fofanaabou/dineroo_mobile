import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_scaffold.dart';

class AppPdfViewer extends StatefulWidget {
  final String filePath;
  final String? title;
  final bool showBack;
  final bool showCartIcon;
  final bool enableSwipe;
  final bool swipeHorizontal;
  final bool autoSpacing;
  final bool pageFling;

  final Widget? loading;
  final Widget Function(String error)? errorBuilder;

  const AppPdfViewer({
    super.key,
    required this.filePath,
    this.title,
    this.showBack = true,
    this.showCartIcon = false,
    this.enableSwipe = true,
    this.swipeHorizontal = false,
    this.autoSpacing = true,
    this.pageFling = true,
    this.loading,
    this.errorBuilder,
  });

  @override
  State<AppPdfViewer> createState() => _AppPdfViewerState();
}

class _AppPdfViewerState extends State<AppPdfViewer> {
  bool _isReady = false;
  String? _error;

  Widget _buildPdf(BuildContext context) {
    final file = File(widget.filePath);

    if (!file.existsSync()) {
      final msg = 'Fichier introuvable: ${widget.filePath}';
      return widget.errorBuilder?.call(msg) ??
          Center(child: Text(msg, textAlign: TextAlign.center));
    }

    return Stack(
      children: [
        PDFView(
          filePath: file.path,
          enableSwipe: widget.enableSwipe,
          swipeHorizontal: widget.swipeHorizontal,
          autoSpacing: widget.autoSpacing,
          pageFling: widget.pageFling,
          onRender: (_) {
            if (!mounted) return;
            setState(() => _isReady = true);
          },
          onError: (e) {
            if (!mounted) return;
            setState(() => _error = e.toString());
          },
          onPageError: (page, e) {
            if (!mounted) return;
            setState(() => _error = 'Page $page: ${e.toString()}');
          },
        ),

        if (!_isReady && _error == null)
          Positioned.fill(
            child: Center(child: widget.loading ?? const AppLoader()),
          ),

        if (_error != null)
          Positioned.fill(
            child:
                widget.errorBuilder?.call(_error!) ??
                Center(
                  child: Text(
                    'Impossible d’afficher le PDF.\n\n$_error',
                    textAlign: TextAlign.center,
                  ),
                ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pdfBody = _buildPdf(context);
    if (widget.title != null && widget.title!.trim().isNotEmpty) {
      return AppScaffold(
        title: widget.title!,
        showBack: widget.showBack,
        showCartIcon: widget.showCartIcon,
        body: pdfBody,
      );
    }
    return pdfBody;
  }
}
