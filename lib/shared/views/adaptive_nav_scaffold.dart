import 'package:dineroo_mobile/shared/common/layout/window_size.dart';
import 'package:dineroo_mobile/shared/views/bottom_nav_bar.dart';
import 'package:flutter/material.dart';

/// App shell navigation: the bottom bar on compact windows, a side [NavigationRail] on medium
/// (labels under icons) and expanded (extended) windows. Destinations come from the same
/// [BottomNavigationBarItem] list the role main views already provide.
class AdaptiveNavScaffold extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onSelected;
  final List<BottomNavigationBarItem> items;
  final Widget body;
  final bool showNavigation;

  const AdaptiveNavScaffold({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    required this.items,
    required this.body,
    this.showNavigation = true,
  });

  @override
  State<AdaptiveNavScaffold> createState() => _AdaptiveNavScaffoldState();
}

class _AdaptiveNavScaffoldState extends State<AdaptiveNavScaffold> {
  // The body sits directly in Scaffold.body on compact windows but inside a Row on wider ones.
  // Without a stable key, crossing a breakpoint would re-create the current screen's State
  // (scroll position, in-flight fetches, typed input).
  final GlobalKey _bodyKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    // Checked here rather than in the constructor: List.length is not allowed in a const
    // constructor's assert.
    assert(
      widget.items.length >= 2,
      'NavigationRail needs at least two destinations, got ${widget.items.length}',
    );
    final size = context.windowSize;
    final body = KeyedSubtree(key: _bodyKey, child: widget.body);

    if (size == WindowSize.compact || !widget.showNavigation) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: body,
        bottomNavigationBar: widget.showNavigation
            ? BottomNavBar(
                currentIndex: widget.currentIndex,
                onTap: widget.onSelected,
                items: widget.items,
              )
            : null,
      );
    }

    final isExpanded = size == WindowSize.expanded;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: widget.currentIndex,
            onDestinationSelected: widget.onSelected,
            extended: isExpanded,
            labelType: isExpanded
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            backgroundColor: Colors.white,
            indicatorColor: Colors.deepOrange.withAlpha(31),
            selectedIconTheme: const IconThemeData(color: Colors.deepOrange),
            unselectedIconTheme: const IconThemeData(color: Colors.grey),
            selectedLabelTextStyle: const TextStyle(color: Colors.deepOrange),
            unselectedLabelTextStyle: const TextStyle(color: Colors.grey),
            destinations: [
              for (final item in widget.items)
                NavigationRailDestination(
                  icon: item.icon,
                  selectedIcon: item.activeIcon,
                  label: Text(item.label ?? ''),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}
