import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_network_image.dart';

class AppQuickAccessNavigationItem {
  final String label;
  final IconData icon;
  final String? imageUrl;
  final VoidCallback onTap;

  const AppQuickAccessNavigationItem({
    required this.label,
    required this.icon,
    this.imageUrl,
    required this.onTap,
  });
}

class AppQuickAccessNavigationDelegate extends SliverPersistentHeaderDelegate {
  final List<AppQuickAccessNavigationItem> items;
  final ValueListenable<String?> selectedLabelListenable;
  final String defaultSelectedLabel;
  final double height;

  const AppQuickAccessNavigationDelegate({
    required this.items,
    required this.selectedLabelListenable,
    required this.defaultSelectedLabel,
    this.height = 56,
  });

  @override
  double get minExtent => items.isEmpty ? 0 : height;

  @override
  double get maxExtent => items.isEmpty ? 0 : height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: overlapsContent
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ValueListenableBuilder<String?>(
        valueListenable: selectedLabelListenable,
        builder: (context, selectedLabel, _) {
          final effectiveSelectedLabel = selectedLabel ?? defaultSelectedLabel;

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 7),
            itemBuilder: (context, index) {
              final item = items[index];
              final selected = item.label == effectiveSelectedLabel;

              return GestureDetector(
                onTap: item.onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFFFEAD6)
                        : const Color(0xFFF6F6F6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _QuickAccessLeading(item: item, selected: selected),
                      const SizedBox(width: 6),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFFD35400)
                              : Colors.black87,
                          fontWeight: selected
                              ? FontWeight.w900
                              : FontWeight.w700,
                          fontSize: 13,
                        ),
                        child: Text(item.label),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(covariant AppQuickAccessNavigationDelegate oldDelegate) {
    return oldDelegate.items.length != items.length ||
        oldDelegate.selectedLabelListenable != selectedLabelListenable ||
        oldDelegate.defaultSelectedLabel != defaultSelectedLabel ||
        oldDelegate.height != height ||
        oldDelegate.items.map((item) => item.label).join('|') !=
            items.map((item) => item.label).join('|');
  }
}

class _QuickAccessLeading extends StatelessWidget {
  final AppQuickAccessNavigationItem item;
  final bool selected;

  const _QuickAccessLeading({required this.item, required this.selected});

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageUrl?.trim() ?? '';
    if (imageUrl.isNotEmpty) {
      return Container(
        width: 22,
        height: 22,
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? const Color(0xFFFFD7B5)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        child: AppNetworkImage(
          imageUrl: imageUrl,
          width: 19,
          height: 19,
          borderRadius: 999,
        ),
      );
    }

    return Icon(
      item.icon,
      size: 16,
      color: selected ? const Color(0xFFD35400) : Colors.black87,
    );
  }
}
