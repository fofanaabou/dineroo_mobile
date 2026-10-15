import 'package:flutter/material.dart';

class RecentSearchesSection extends StatelessWidget {
  final List<String> recentSearches;
  final String? activeSearch;
  final VoidCallback onClearAll;
  final ValueChanged<String> onSearchSelected;

  const RecentSearchesSection({
    super.key,
    required this.recentSearches,
    required this.onClearAll,
    required this.onSearchSelected,
    this.activeSearch,
  });

  @override
  Widget build(BuildContext context) {
    if (recentSearches.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recherches récentes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: onClearAll,
                child: const Text(
                  'Tout effacer',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                recentSearches.map((term) {
                  final isActive =
                      activeSearch?.trim().toLowerCase() ==
                      term.trim().toLowerCase();
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.transparent, width: 1.5),
                    ),
                    child: GestureDetector(
                      onTap: isActive ? null : () => onSearchSelected(term),
                      child: Text(
                        term.length > 20 ? '${term.substring(0, 20)}…' : term,
                        style: TextStyle(
                          fontSize: 14,
                          color: isActive ? Colors.deepOrange : Colors.black87,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}
