import 'package:flutter/material.dart';

class AppIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  const AppIcon({super.key, required this.icon, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, color: color ?? Colors.black),
      ),
    );
  }
}
