import 'package:flutter/material.dart';

class ManagerOrderCount extends StatelessWidget {
  final String count;
  final String label;

  const ManagerOrderCount({
    super.key,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF838799),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
