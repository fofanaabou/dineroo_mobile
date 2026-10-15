import 'package:flutter/material.dart';

class GoOfflineButton extends StatelessWidget {
  final Future<void> Function()? onPressed;
  final bool isLoading;

  const GoOfflineButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  bool get _disabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _disabled ? 0.7 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: ElevatedButton(
        onPressed: _disabled ? null : () async => await onPressed!(),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF3326),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading) ...[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              isLoading ? "..." : "Passer hors ligne",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
