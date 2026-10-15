import 'package:flutter/material.dart';

class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isDisabled;
  final Color backgroundColor;
  final Color iconColor;

  const AppBackButton({
    super.key,
    this.onPressed,
    this.isDisabled = false,
    this.backgroundColor = const Color(0xFFECF0F4),
    this.iconColor = const Color(0xFF181C2E),
  });

  @override
  Widget build(BuildContext context) {
    void handleBack() {
      if (onPressed != null) {
        onPressed!();
        return;
      }
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1,
        child: GestureDetector(
          onTap: isDisabled ? null : handleBack,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chevron_left, color: iconColor, size: 20),
          ),
        ),
      ),
    );
  }
}
