import 'package:flutter/material.dart';
import 'app_button.dart';

class AppErrorRetry extends StatelessWidget {
  static const String defaultMessage = 'Oups, un problème est survenu.';

  final VoidCallback onPressed;
  final String message;
  final Icon? icon;

  const AppErrorRetry({
    super.key,
    required this.onPressed,
    this.message = defaultMessage,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon ?? const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 180,
            child: AppButton(
              icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
              iconPosition: IconPosition.start,
              text: 'Réessayer',
              onPressed: onPressed,
            ),
          ),
        ],
      ),
    );
  }
}
