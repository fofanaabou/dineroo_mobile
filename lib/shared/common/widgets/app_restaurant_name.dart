import 'package:flutter/material.dart';

class AppRestaurantName extends StatelessWidget {
  final String? name;
  final bool centered;

  const AppRestaurantName({
    super.key,
    required this.name,
    this.centered = false,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedName = (name ?? '').trim();
    if (trimmedName.isEmpty) return const SizedBox.shrink();

    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.storefront_outlined,
            size: 14,
            color: Colors.black54,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              trimmedName,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    return Align(
      alignment: centered ? Alignment.center : Alignment.centerLeft,
      child: content,
    );
  }
}
