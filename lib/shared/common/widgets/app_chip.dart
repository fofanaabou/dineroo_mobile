import 'package:flutter/material.dart';

class AppChip extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final int maxLines;
  final TextOverflow overflow;

  const AppChip({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}
