import 'package:flutter/material.dart';

class AppCloseButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AppCloseButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 45,
      height: 45,
      decoration: const BoxDecoration(
        color: Color(0xFFF0F4F9),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.close, color: Colors.black),
        onPressed: onPressed,
        splashRadius: 22,
      ),
    );
  }
}
