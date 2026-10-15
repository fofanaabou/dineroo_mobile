import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/views/bottom_nav_bar.dart';

class BaseMainView extends StatefulWidget {
  final List<BottomNavigationBarItem> navItems;
  final Widget Function(int index) screenBuilder;
  final bool hideBottomNav;
  final int initialIndex;

  const BaseMainView({
    super.key,
    required this.navItems,
    required this.screenBuilder,
    this.hideBottomNav = false,
    this.initialIndex = 0,
  });

  static void switchTo(
    BuildContext context,
    int index, {
    bool rebuild = false,
    bool addToHistory = false,
  }) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_BaseMainNavigationScope>();
    scope?.switchTo(index, rebuild: rebuild, addToHistory: addToHistory);
  }

  @override
  State<BaseMainView> createState() => _BaseNavigationViewState();
}

class _BaseNavigationViewState extends State<BaseMainView> {
  late int _selectedIndex;
  late final List<Widget?> _screens;
  final List<int> _tabHistory = [];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _screens = List.filled(widget.navItems.length, null);
    _screens[_selectedIndex] = widget.screenBuilder(_selectedIndex);
  }

  void _onItemTapped(
    int index, {
    bool rebuild = false,
    bool addToHistory = false,
  }) {
    setState(() {
      if (addToHistory && index != _selectedIndex) {
        _tabHistory.add(_selectedIndex);
      }
      _selectedIndex = index;
      if (rebuild) {
        _screens[index] = widget.screenBuilder(index);
      } else {
        _screens[index] ??= widget.screenBuilder(index);
      }
    });
  }

  void _goBackToPreviousTab() {
    if (_tabHistory.isEmpty) return;
    setState(() {
      final previousIndex = _tabHistory.removeLast();
      _selectedIndex = previousIndex;
      _screens[previousIndex] ??= widget.screenBuilder(previousIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _BaseMainNavigationScope(
      switchTo: _onItemTapped,
      child: PopScope(
        canPop: _tabHistory.isEmpty,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _goBackToPreviousTab();
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: _screens[_selectedIndex] ?? const SizedBox(),
          bottomNavigationBar: widget.hideBottomNav
              ? null
              : BottomNavBar(
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
                  items: widget.navItems,
                ),
        ),
      ),
    );
  }
}

class _BaseMainNavigationScope extends InheritedWidget {
  final void Function(int index, {bool rebuild, bool addToHistory}) switchTo;

  const _BaseMainNavigationScope({
    required this.switchTo,
    required super.child,
  });

  @override
  bool updateShouldNotify(_BaseMainNavigationScope oldWidget) => false;
}
