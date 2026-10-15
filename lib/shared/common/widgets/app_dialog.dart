import 'package:flutter/material.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? content;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final String confirmText;
  final String cancelText;
  final bool showCancel;
  final bool isShiftedUp;
  final bool isConfirmLoading;

  static const TextStyle defaultContentStyle = TextStyle(
    color: Color(0xFF4F5673),
    fontSize: 16,
    height: 1.5,
  );

  const AppDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.onConfirm,
    this.onCancel,
    this.confirmText = 'Valider',
    this.cancelText = 'Annuler',
    this.showCancel = true,
    this.isShiftedUp = false,
    this.isConfirmLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (message == null && content == null) {
      throw ArgumentError(
        'AppDialog requires either a message or a content widget.',
      );
    }

    return Transform.translate(
      offset: Offset(0, isShiftedUp ? -40 : 0),
      child: AlertDialog(
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 20,
            fontWeight: FontWeight.w400,
          ),
        ),
        content: _buildContent(),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          if (showCancel)
            TextButton(
              onPressed: onCancel ?? () => Navigator.of(context).pop(),
              child: Text(cancelText.toUpperCase()),
            ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: isConfirmLoading
                ? null
                : onConfirm ?? () => Navigator.of(context).pop(),
            child: isConfirmLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    confirmText.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Roboto',
                      letterSpacing: 1,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (content != null) {
      if (content is RichText) {
        final RichText richText = content as RichText;
        final span = richText.text;

        if (span is TextSpan && span.style == null) {
          return RichText(
            text: TextSpan(style: defaultContentStyle, children: span.children),
          );
        }
      }
      return content!;
    }

    return Text(
      message!,
      textAlign: TextAlign.center,
      style: defaultContentStyle,
    );
  }
}
