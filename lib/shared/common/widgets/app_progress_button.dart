import 'package:flutter/material.dart';

class AppProgressButton extends StatelessWidget {
  final double progress;
  final VoidCallback onPressed;
  final String label;
  final int? remainingSeconds;

  const AppProgressButton({
    super.key,
    required this.progress,
    required this.onPressed,
    this.label = 'Accepter',
    this.remainingSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final buttonLabel =
        remainingSeconds != null ? '$label (${remainingSeconds!})' : label;

    return SizedBox(
      width: double.infinity,
      height: 57.08,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFF7622),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(color: const Color(0xFFFFA15C)),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: onPressed,
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
