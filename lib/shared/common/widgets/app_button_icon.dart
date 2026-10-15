import 'package:flutter/material.dart';

class AppButtonIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color iconColor;
  final double size;
  final bool isDisabled;

  const AppButtonIcon({
    super.key,
    required this.icon,
    required this.onTap,
    required this.backgroundColor,
    required this.iconColor,
    this.size = 16,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: isDisabled ? null : onTap,
        child: CircleAvatar(
          radius: size,
          backgroundColor: backgroundColor,
          child: Icon(icon, size: size, color: iconColor),
        ),
      ),
    );
  }
}
