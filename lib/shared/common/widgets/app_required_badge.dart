import 'package:flutter/material.dart';

class AppRequiredBadge extends StatelessWidget {
  final bool isSatisfied;

  const AppRequiredBadge({super.key, required this.isSatisfied});

  @override
  Widget build(BuildContext context) {
    if (isSatisfied) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Obligatoire',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.deepOrange,
        ),
      ),
    );
  }
}
