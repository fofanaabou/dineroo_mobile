import 'package:flutter/material.dart';

class AppInfoPill extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;
  final Color backgroundColor;
  final int maxLines;

  const AppInfoPill({
    super.key,
    this.icon,
    required this.label,
    this.color = Colors.black54,
    this.backgroundColor = const Color(0xFFF6F6F6),
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: maxLines,
              softWrap: maxLines > 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
