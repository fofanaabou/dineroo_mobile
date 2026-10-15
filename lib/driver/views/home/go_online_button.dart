import 'package:flutter/material.dart';

class GoOnlineButton extends StatelessWidget {
  final Future<void> Function()? onPressed;
  final bool isLoading;

  const GoOnlineButton({
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
      child: Container(
        width: double.infinity,
        color: Colors.green,
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 24),
        child: TextButton(
          onPressed: _disabled ? null : () async => await onPressed!(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading) ...[
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 14),
              ] else ...[
                const Text(
                  "➤",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 17),
              ],
              Text(
                isLoading ? "Connexion..." : "Passer en ligne",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
