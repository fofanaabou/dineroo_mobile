import 'package:dineroo_mobile/shared/common/widgets/app_button.dart';
import 'package:flutter/material.dart';

class AppBottomSheet extends StatelessWidget {
  final IconData? icon;
  final Color iconColor;
  final String title;
  final String? message;
  final Widget? content;
  final String confirmText;
  final VoidCallback? onConfirm;
  final EdgeInsetsGeometry? padding;

  const AppBottomSheet({
    super.key,
    this.icon,
    this.iconColor = Colors.orange,
    required this.title,
    this.message,
    this.content,
    this.confirmText = 'D\'accord',
    this.onConfirm,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final Widget mainContent =
        content ??
        Text(
          message ?? '',
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          textAlign: TextAlign.center,
        );

    final effectivePadding =
        padding ??
        const EdgeInsets.only(left: 24, right: 24, top: 32, bottom: 32);

    return SafeArea(
      child: Padding(
        padding: effectivePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) Icon(icon, size: 40, color: iconColor),
            if (icon != null) const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            mainContent,
            const SizedBox(height: 24),
            AppButton(
              text: confirmText,
              onPressed: onConfirm ?? () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
