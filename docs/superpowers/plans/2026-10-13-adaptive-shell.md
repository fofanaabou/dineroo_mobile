# Adaptive Shell (web and tablet, first slice) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the shared navigation shell, role-selection, location and auth screens adapt to window size (web and tablet) while phones stay pixel-identical, and make lists scrollable with a mouse.

**Architecture:** One window-size vocabulary (`WindowSize`) drives small shared building blocks: an `AdaptiveNavScaffold` (bottom bar on compact, `NavigationRail` on medium/expanded) adopted by the two existing shells, an `AdaptiveContent` max-width wrapper for centered content, an `AuthLayout` card layout on wide windows, an `AppScrollBehavior` for mouse drag, and a theme-level dialog width cap. Compact windows keep today's code paths.

**Tech Stack:** Flutter 3.44 (Dart 3.12), Material 3, `flutter_test` widget tests, headless Chrome for browser checks. No new dependencies.

**Spec:** `docs/superpowers/specs/2026-10-12-adaptive-shell-design.md`

## Preflight

The web foundation work (sub-project 0) is still uncommitted on branch `feat/web-support-foundation`. Before Task 1 ask the user whether to commit it first or keep building on top of it uncommitted. Do not commit anything yourself unless the user asks.

## Global Constraints

- Breakpoints (Material 3): compact < 600px, medium 600 to under 840px, expanded >= 840px.
- Navigation: compact keeps the existing `BottomNavBar`; medium shows a `NavigationRail` with labels under icons; expanded shows an extended rail.
- Maximum content widths: role selection and location screens 420px, auth card 480px, dialogs 560px. Bottom sheets keep the Material 3 default of 640px (verified in `bottom_sheet.dart`), so no sheet change.
- Compact (phone) layout must stay identical to today.
- Nav items stay `List<BottomNavigationBarItem>`; `CustomerMainView`, `DriverMainView` and `ManagerMainView` must not need edits. `hideBottomNav` keeps working.
- No new dependencies. Portrait lock in `main.dart`, `AndroidManifest.xml` and `Info.plist` stays untouched.
- Out of scope: customer and manager screen layouts, Enter-to-submit and autofill on forms, routing, payment, uploads, push.
- Repo rules: never run `dart format` on an existing file (the repo is not formatted to the current formatter and it creates unrelated churn); format only files you create. Check `git diff` for churn after editing existing files.
- Commits only when the user asks; never add a `Co-Authored-By` trailer (the user is the sole author). Each task's final step shows the intended message.
- Flutter's default widget-test window is 800x600 logical pixels (a medium width). Every new test pins its size with `setWindowSize` from Task 1.
- Run tests from the repo root: `/Users/aboufofana/Desktop/workspace/dineroo/frontend/dineroo_mobile`.

## Review Focus

Failure modes the spec implies but a happy-path test would miss; each is pinned by a test in the owning task.

1. Resizing the window across a breakpoint while a tab is selected must keep the selected tab and the already built tab screens (Task 4).
2. A short window (height 500) with a tall auth form on a wide screen must scroll, not overflow (Task 6).
3. The role-selection screen on a short, wide window must scroll, not overflow (Task 5).
4. `showNavigation` flipping at runtime on a wide window (driver "hide menus") must remove the rail and give the body the full width (Task 3).
5. The real manager labels ('Commandes', 'Catalogue') in the narrowest rail (600px) must render without overflow (Task 4).

## File Structure

| File | Responsibility |
|---|---|
| `lib/shared/common/layout/window_size.dart` (new) | `WindowSize` enum, `fromWidth`, `BuildContext.windowSize` |
| `lib/shared/common/layout/adaptive_content.dart` (new) | `ContentWidth` constants, `AdaptiveContent` centered max-width wrapper |
| `lib/shared/common/layout/app_scroll_behavior.dart` (new) | Mouse, trackpad and stylus drag scrolling |
| `lib/shared/common/config/app_theme.dart` (new) | `buildAppTheme()` extracted from `main.dart`, plus the dialog width cap |
| `lib/shared/views/adaptive_nav_scaffold.dart` (new) | Bottom bar or rail depending on size |
| `lib/shared/views/base_main_view.dart` (modify) | Use `AdaptiveNavScaffold` |
| `lib/shared/views/base_main_wrapper.dart` (modify) | Use `AdaptiveNavScaffold` |
| `lib/shared/views/auth/whoiam_view.dart` (modify) | Wrap content in `AdaptiveContent` |
| `lib/shared/views/location/location_access_view.dart` (modify) | Wrap content in `AdaptiveContent` |
| `lib/shared/views/auth/auth_layout.dart` (modify) | Card layout on medium and expanded |
| `lib/main.dart` (modify) | `scrollBehavior`, `theme: buildAppTheme()` |
| `test/helpers/window_size_helper.dart` (new) | `setWindowSize` test helper |

---

### Task 1: Window size classes and test helper

**Files:**
- Create: `lib/shared/common/layout/window_size.dart`
- Create: `test/helpers/window_size_helper.dart`
- Test: `test/shared/common/layout/window_size_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `enum WindowSize { compact, medium, expanded }` with `static const double mediumBreakpoint = 600`, `static const double expandedBreakpoint = 840`, `static WindowSize fromWidth(double width)`.
  - `extension WindowSizeContext on BuildContext { WindowSize get windowSize }`.
  - `void setWindowSize(WidgetTester tester, double width, [double height = 900])` in `test/helpers/window_size_helper.dart`.

- [ ] **Step 1: Write the test helper**

Create `test/helpers/window_size_helper.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the logical window size for the rest of the test. The default test window is 800x600,
/// which is already a medium width, so adaptive tests must always set their own size.
void setWindowSize(WidgetTester tester, double width, [double height = 900]) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.reset);
}
```

- [ ] **Step 2: Write the failing test**

Create `test/shared/common/layout/window_size_test.dart`:

```dart
import 'package:dineroo_mobile/shared/common/layout/window_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/window_size_helper.dart';

void main() {
  group('WindowSize.fromWidth', () {
    test('is compact below 600', () {
      expect(WindowSize.fromWidth(0), WindowSize.compact);
      expect(WindowSize.fromWidth(390), WindowSize.compact);
      expect(WindowSize.fromWidth(599.9), WindowSize.compact);
    });

    test('is medium from 600 up to 840', () {
      expect(WindowSize.fromWidth(600), WindowSize.medium);
      expect(WindowSize.fromWidth(768), WindowSize.medium);
      expect(WindowSize.fromWidth(839.9), WindowSize.medium);
    });

    test('is expanded from 840', () {
      expect(WindowSize.fromWidth(840), WindowSize.expanded);
      expect(WindowSize.fromWidth(1920), WindowSize.expanded);
    });
  });

  testWidgets('BuildContext.windowSize follows the window width', (
    tester,
  ) async {
    late WindowSize seen;
    setWindowSize(tester, 390);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            seen = context.windowSize;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(seen, WindowSize.compact);

    setWindowSize(tester, 700);
    await tester.pump();
    expect(seen, WindowSize.medium);

    setWindowSize(tester, 1200);
    await tester.pump();
    expect(seen, WindowSize.expanded);
  });
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `flutter test test/shared/common/layout/window_size_test.dart`
Expected: FAIL to compile with `Target of URI doesn't exist: 'package:dineroo_mobile/shared/common/layout/window_size.dart'`.

- [ ] **Step 4: Write the minimal implementation**

Create `lib/shared/common/layout/window_size.dart`:

```dart
import 'package:flutter/widgets.dart';

/// Material 3 window size classes: the single vocabulary for adaptive layouts.
enum WindowSize {
  compact,
  medium,
  expanded;

  static const double mediumBreakpoint = 600;
  static const double expandedBreakpoint = 840;

  static WindowSize fromWidth(double width) {
    if (width >= expandedBreakpoint) return WindowSize.expanded;
    if (width >= mediumBreakpoint) return WindowSize.medium;
    return WindowSize.compact;
  }
}

extension WindowSizeContext on BuildContext {
  WindowSize get windowSize =>
      WindowSize.fromWidth(MediaQuery.sizeOf(this).width);
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `dart format lib/shared/common/layout/window_size.dart test/helpers/window_size_helper.dart test/shared/common/layout/window_size_test.dart && flutter test test/shared/common/layout/window_size_test.dart`
Expected: `All tests passed!` (4 tests).

- [ ] **Step 6: Commit (only if the user asked for commits)**

```bash
git add lib/shared/common/layout/window_size.dart test/helpers/window_size_helper.dart test/shared/common/layout/window_size_test.dart
git commit -m "feat(layout): add Material 3 window size classes"
```

---

### Task 2: AdaptiveContent (centered max-width wrapper)

**Files:**
- Create: `lib/shared/common/layout/adaptive_content.dart`
- Test: `test/shared/common/layout/adaptive_content_test.dart`

**Interfaces:**
- Consumes: `WindowSize`, `context.windowSize` (Task 1); `setWindowSize` (Task 1).
- Produces:
  - `abstract final class ContentWidth { static const double roleSelection = 420; static const double authCard = 480; }`
  - `AdaptiveContent({Key? key, required double maxWidth, required Widget child})`: returns `child` untouched on compact windows; on medium and expanded it top-centers `child` with `BoxConstraints(maxWidth: maxWidth)`.

- [ ] **Step 1: Write the failing test**

Create `test/shared/common/layout/adaptive_content_test.dart`:

```dart
import 'package:dineroo_mobile/shared/common/layout/adaptive_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/window_size_helper.dart';

const _probe = Key('probe');

Widget _app() => MaterialApp(
  home: Scaffold(
    body: AdaptiveContent(
      maxWidth: 420,
      child: const SizedBox(key: _probe, width: double.infinity, height: 10),
    ),
  ),
);

void main() {
  group('AdaptiveContent', () {
    testWidgets('leaves the child untouched on a compact window', (
      tester,
    ) async {
      setWindowSize(tester, 390);
      await tester.pumpWidget(_app());

      expect(tester.getSize(find.byKey(_probe)).width, 390);
    });

    testWidgets('caps and centers the child on a medium window', (
      tester,
    ) async {
      setWindowSize(tester, 700);
      await tester.pumpWidget(_app());

      expect(tester.getSize(find.byKey(_probe)).width, 420);
      expect(tester.getCenter(find.byKey(_probe)).dx, closeTo(350, 0.5));
    });

    testWidgets('caps and centers the child on an expanded window', (
      tester,
    ) async {
      setWindowSize(tester, 1200);
      await tester.pumpWidget(_app());

      expect(tester.getSize(find.byKey(_probe)).width, 420);
      expect(tester.getCenter(find.byKey(_probe)).dx, closeTo(600, 0.5));
    });

    testWidgets('does not widen a child narrower than the maximum', (
      tester,
    ) async {
      setWindowSize(tester, 1200);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveContent(
              maxWidth: 420,
              child: const SizedBox(key: _probe, width: 200, height: 10),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byKey(_probe)).width, 200);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/shared/common/layout/adaptive_content_test.dart`
Expected: FAIL to compile with `Target of URI doesn't exist: 'package:dineroo_mobile/shared/common/layout/adaptive_content.dart'`.

- [ ] **Step 3: Write the minimal implementation**

Create `lib/shared/common/layout/adaptive_content.dart`:

```dart
import 'package:dineroo_mobile/shared/common/layout/window_size.dart';
import 'package:flutter/widgets.dart';

abstract final class ContentWidth {
  static const double roleSelection = 420;
  static const double authCard = 480;
}

/// Centers [child] with a maximum width on medium and expanded windows. On compact windows it
/// returns [child] untouched so phones keep their current layout.
class AdaptiveContent extends StatelessWidget {
  final double maxWidth;
  final Widget child;

  const AdaptiveContent({
    super.key,
    required this.maxWidth,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (context.windowSize == WindowSize.compact) return child;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `dart format lib/shared/common/layout/adaptive_content.dart test/shared/common/layout/adaptive_content_test.dart && flutter test test/shared/common/layout/adaptive_content_test.dart`
Expected: `All tests passed!` (4 tests).

- [ ] **Step 5: Commit (only if the user asked for commits)**

```bash
git add lib/shared/common/layout/adaptive_content.dart test/shared/common/layout/adaptive_content_test.dart
git commit -m "feat(layout): add AdaptiveContent max-width wrapper"
```

---

### Task 3: AdaptiveNavScaffold

**Files:**
- Create: `lib/shared/views/adaptive_nav_scaffold.dart`
- Test: `test/shared/views/adaptive_nav_scaffold_test.dart`

**Interfaces:**
- Consumes: `WindowSize`, `context.windowSize` (Task 1); `BottomNavBar` from `lib/shared/views/bottom_nav_bar.dart` (existing: `BottomNavBar({required int currentIndex, required ValueChanged<int> onTap, required List<BottomNavigationBarItem> items})`); `setWindowSize` (Task 1).
- Produces: `AdaptiveNavScaffold({Key? key, required int currentIndex, required ValueChanged<int> onSelected, required List<BottomNavigationBarItem> items, required Widget body, bool showNavigation = true})`. Non-const constructor with `assert(items.length >= 2)`.

- [ ] **Step 1: Write the failing test**

Create `test/shared/views/adaptive_nav_scaffold_test.dart`:

```dart
import 'package:dineroo_mobile/shared/views/adaptive_nav_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/window_size_helper.dart';

const _items = [
  BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Accueil'),
  BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Commandes'),
];

Widget _app({
  int currentIndex = 0,
  ValueChanged<int>? onSelected,
  bool showNavigation = true,
}) => MaterialApp(
  home: AdaptiveNavScaffold(
    currentIndex: currentIndex,
    onSelected: onSelected ?? (_) {},
    items: _items,
    showNavigation: showNavigation,
    body: const Center(child: Text('contenu')),
  ),
);

NavigationRail _rail(WidgetTester tester) =>
    tester.widget<NavigationRail>(find.byType(NavigationRail));

void main() {
  group('AdaptiveNavScaffold', () {
    testWidgets('uses the bottom bar on a compact window', (tester) async {
      setWindowSize(tester, 390);
      await tester.pumpWidget(_app());

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('contenu'), findsOneWidget);
    });

    testWidgets('uses a labelled rail on a medium window', (tester) async {
      setWindowSize(tester, 700);
      await tester.pumpWidget(_app());

      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(_rail(tester).extended, isFalse);
      expect(_rail(tester).labelType, NavigationRailLabelType.all);
      expect(find.text('contenu'), findsOneWidget);
    });

    testWidgets('uses an extended rail on an expanded window', (tester) async {
      setWindowSize(tester, 1200);
      await tester.pumpWidget(_app());

      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(_rail(tester).extended, isTrue);
    });

    testWidgets('switches layout exactly at the 600 and 840 breakpoints', (
      tester,
    ) async {
      Future<void> pumpAt(double width) async {
        setWindowSize(tester, width);
        await tester.pumpWidget(_app());
      }

      await pumpAt(599);
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      await pumpAt(600);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(_rail(tester).extended, isFalse);

      await pumpAt(839);
      expect(_rail(tester).extended, isFalse);

      await pumpAt(840);
      expect(_rail(tester).extended, isTrue);
    });

    for (final width in [390.0, 700.0, 1200.0]) {
      testWidgets('reports the tapped destination at ${width}px', (
        tester,
      ) async {
        final selected = <int>[];
        setWindowSize(tester, width);
        await tester.pumpWidget(_app(onSelected: selected.add));

        await tester.tap(find.text('Commandes'));
        await tester.pump();

        expect(selected, [1]);
      });
    }

    testWidgets('marks the current destination as selected', (tester) async {
      setWindowSize(tester, 390);
      await tester.pumpWidget(_app(currentIndex: 1));
      expect(
        tester
            .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
            .currentIndex,
        1,
      );

      setWindowSize(tester, 700);
      await tester.pumpWidget(_app(currentIndex: 1));
      expect(_rail(tester).selectedIndex, 1);
    });

    testWidgets('hides all navigation when showNavigation is false', (
      tester,
    ) async {
      setWindowSize(tester, 390);
      await tester.pumpWidget(_app(showNavigation: false));
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.byType(NavigationRail), findsNothing);

      setWindowSize(tester, 1200);
      await tester.pumpWidget(_app(showNavigation: false));
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('gives the body the full width when navigation is hidden at runtime', (
      tester,
    ) async {
      setWindowSize(tester, 1200);
      await tester.pumpWidget(_app());
      expect(tester.getCenter(find.text('contenu')).dx, greaterThan(600));

      await tester.pumpWidget(_app(showNavigation: false));

      expect(find.byType(NavigationRail), findsNothing);
      expect(tester.getCenter(find.text('contenu')).dx, closeTo(600, 0.5));
    });

    test('rejects fewer than two destinations', () {
      expect(
        () => AdaptiveNavScaffold(
          currentIndex: 0,
          onSelected: (_) {},
          items: [_items.first],
          body: const SizedBox(),
        ),
        throwsAssertionError,
      );
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/shared/views/adaptive_nav_scaffold_test.dart`
Expected: FAIL to compile with `Target of URI doesn't exist: 'package:dineroo_mobile/shared/views/adaptive_nav_scaffold.dart'`.

- [ ] **Step 3: Write the minimal implementation**

Create `lib/shared/views/adaptive_nav_scaffold.dart`:

```dart
import 'package:dineroo_mobile/shared/common/layout/window_size.dart';
import 'package:dineroo_mobile/shared/views/bottom_nav_bar.dart';
import 'package:flutter/material.dart';

/// App shell navigation: the bottom bar on compact windows, a side [NavigationRail] on medium
/// (labels under icons) and expanded (extended) windows. Destinations come from the same
/// [BottomNavigationBarItem] list the role main views already provide.
class AdaptiveNavScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelected;
  final List<BottomNavigationBarItem> items;
  final Widget body;
  final bool showNavigation;

  AdaptiveNavScaffold({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    required this.items,
    required this.body,
    this.showNavigation = true,
  }) : assert(
         items.length >= 2,
         'NavigationRail needs at least two destinations, got ${items.length}',
       );

  @override
  Widget build(BuildContext context) {
    final size = context.windowSize;

    if (size == WindowSize.compact || !showNavigation) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: body,
        bottomNavigationBar: showNavigation
            ? BottomNavBar(
                currentIndex: currentIndex,
                onTap: onSelected,
                items: items,
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
            selectedIndex: currentIndex,
            onDestinationSelected: onSelected,
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
              for (final item in items)
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
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `dart format lib/shared/views/adaptive_nav_scaffold.dart test/shared/views/adaptive_nav_scaffold_test.dart && flutter test test/shared/views/adaptive_nav_scaffold_test.dart`
Expected: `All tests passed!` (13 tests). If a tap test fails on the rail, check that `find.text('Commandes')` matches exactly one widget at that width.

- [ ] **Step 5: Commit (only if the user asked for commits)**

```bash
git add lib/shared/views/adaptive_nav_scaffold.dart test/shared/views/adaptive_nav_scaffold_test.dart
git commit -m "feat(shell): add adaptive bottom bar / navigation rail scaffold"
```

---

### Task 4: Adopt the scaffold in BaseMainView and BaseMainWrapper

**Files:**
- Modify: `lib/shared/views/base_main_view.dart` (imports; the `Scaffold` inside `build`)
- Modify: `lib/shared/views/base_main_wrapper.dart` (imports; `build`)
- Modify (append tests): `test/shared/views/base_main_view_test.dart`
- Create (test): `test/shared/views/base_main_wrapper_test.dart`

**Interfaces:**
- Consumes: `AdaptiveNavScaffold` (Task 3); `setWindowSize` (Task 1); existing `ManagerMainView.bottomNavItems` (const icons only), `UserRole` enum declared in `base_main_wrapper.dart`.
- Produces: no new public API. `BaseMainView` and `BaseMainWrapper` render the rail on medium and expanded windows.

- [ ] **Step 1: Write the failing tests for BaseMainView**

In `test/shared/views/base_main_view_test.dart`, add these imports at the top (keep the existing ones):

```dart
import 'package:dineroo_mobile/manager/views/manager_main_view.dart';

import '../../helpers/window_size_helper.dart';
```

Add this top-level code above `void main()`:

```dart
const _items = [
  BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Accueil'),
  BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Commandes'),
];

Widget _shell({bool hideBottomNav = false}) => MaterialApp(
  home: BaseMainView(
    navItems: _items,
    hideBottomNav: hideBottomNav,
    screenBuilder: (index) =>
        Center(child: Text(index == 0 ? 'Espace accueil' : 'Espace commandes')),
  ),
);
```

Append these tests inside `main()` after the existing test:

```dart
  testWidgets('shows the bottom bar on a compact window', (tester) async {
    setWindowSize(tester, 390);
    await tester.pumpWidget(_shell());

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('shows the extended rail on an expanded window', (tester) async {
    setWindowSize(tester, 1200);
    await tester.pumpWidget(_shell());

    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
      isTrue,
    );
  });

  testWidgets('keeps the selected tab when the window crosses a breakpoint', (
    tester,
  ) async {
    setWindowSize(tester, 1200);
    await tester.pumpWidget(_shell());
    await tester.tap(find.text('Commandes'));
    await tester.pumpAndSettle();
    expect(find.text('Espace commandes'), findsOneWidget);

    setWindowSize(tester, 390);
    await tester.pumpAndSettle();

    expect(find.text('Espace commandes'), findsOneWidget);
    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .currentIndex,
      1,
    );
  });

  testWidgets('hides the navigation when hideBottomNav is set', (tester) async {
    setWindowSize(tester, 390);
    await tester.pumpWidget(_shell(hideBottomNav: true));
    expect(find.byType(BottomNavigationBar), findsNothing);

    setWindowSize(tester, 1200);
    await tester.pumpWidget(_shell(hideBottomNav: true));
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('renders the manager labels in the narrowest rail', (
    tester,
  ) async {
    setWindowSize(tester, 600);
    await tester.pumpWidget(
      MaterialApp(
        home: BaseMainView(
          navItems: ManagerMainView.bottomNavItems,
          screenBuilder: (_) => const SizedBox(),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Commandes'), findsOneWidget);
    expect(find.text('Catalogue'), findsOneWidget);
  });
```

- [ ] **Step 2: Write the failing tests for BaseMainWrapper**

Create `test/shared/views/base_main_wrapper_test.dart`:

```dart
import 'package:dineroo_mobile/shared/views/base_main_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/window_size_helper.dart';

// The manager role is used because its nav items are plain icons (no providers needed).
Widget _wrapper() => MaterialApp(
  home: BaseMainWrapper(
    selectedIndex: 1,
    role: UserRole.manager,
    child: const Center(child: Text('page')),
  ),
);

void main() {
  group('BaseMainWrapper', () {
    testWidgets('shows the bottom bar on a compact window', (tester) async {
      setWindowSize(tester, 390);
      await tester.pumpWidget(_wrapper());

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('page'), findsOneWidget);
    });

    testWidgets('shows the extended rail on an expanded window', (tester) async {
      setWindowSize(tester, 1200);
      await tester.pumpWidget(_wrapper());

      expect(find.byType(BottomNavigationBar), findsNothing);
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isTrue);
      expect(rail.selectedIndex, 1);
      expect(find.text('page'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `flutter test test/shared/views/base_main_view_test.dart test/shared/views/base_main_wrapper_test.dart`
Expected: FAIL. The expanded-window tests fail with `Expected: no matching candidates / Actual: BottomNavigationBar` (the shells still render the bottom bar at 1200px) and the resize test fails to find a `NavigationRail`. The existing test and the two compact tests pass.

- [ ] **Step 4: Adopt the scaffold in `BaseMainView`**

In `lib/shared/views/base_main_view.dart` replace the import line

```dart
import 'package:dineroo_mobile/shared/views/bottom_nav_bar.dart';
```

with

```dart
import 'package:dineroo_mobile/shared/views/adaptive_nav_scaffold.dart';
```

and replace the `Scaffold` inside `build`

```dart
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
```

with

```dart
        child: AdaptiveNavScaffold(
          currentIndex: _selectedIndex,
          onSelected: _onItemTapped,
          items: widget.navItems,
          showNavigation: !widget.hideBottomNav,
          body: _screens[_selectedIndex] ?? const SizedBox(),
        ),
```

- [ ] **Step 5: Adopt the scaffold in `BaseMainWrapper`**

In `lib/shared/views/base_main_wrapper.dart` replace the import line

```dart
import 'package:dineroo_mobile/shared/views/bottom_nav_bar.dart';
```

with

```dart
import 'package:dineroo_mobile/shared/views/adaptive_nav_scaffold.dart';
```

and replace the body of `build`

```dart
    return Scaffold(
      backgroundColor: Colors.white,
      body: child,
      bottomNavigationBar: BottomNavBar(
        currentIndex: selectedIndex,
        onTap: (index) => _handleNavTap(context, role, index),
        items: _getNavItems(role),
      ),
    );
```

with

```dart
    return AdaptiveNavScaffold(
      currentIndex: selectedIndex,
      onSelected: (index) => _handleNavTap(context, role, index),
      items: _getNavItems(role),
      body: child,
    );
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `dart format test/shared/views/base_main_wrapper_test.dart && flutter test test/shared/views`
Expected: `All tests passed!`. Note: do not run `dart format` on `base_main_view_test.dart`, `base_main_view.dart` or `base_main_wrapper.dart` (existing files). Then `git diff lib/shared/views/base_main_view.dart lib/shared/views/base_main_wrapper.dart` must show only the edits above.

- [ ] **Step 7: Commit (only if the user asked for commits)**

```bash
git add lib/shared/views/base_main_view.dart lib/shared/views/base_main_wrapper.dart test/shared/views/base_main_view_test.dart test/shared/views/base_main_wrapper_test.dart
git commit -m "feat(shell): use the adaptive navigation scaffold in both shells"
```

---

### Task 5: Center the role-selection and location screens

**Files:**
- Modify: `lib/shared/views/auth/whoiam_view.dart` (import; the `Scaffold` returned at the end of `build`)
- Modify: `lib/shared/views/location/location_access_view.dart` (import; `build`)
- Modify (append tests): `test/shared/views/auth/whoiam_view_test.dart`
- Create (test): `test/shared/views/location/location_access_view_test.dart`

**Interfaces:**
- Consumes: `AdaptiveContent`, `ContentWidth.roleSelection` (Task 2); `setWindowSize` (Task 1); `AppButton` (existing, fills its parent's width).
- Produces: no new public API.

- [ ] **Step 1: Write the failing tests for WhoiamView**

In `test/shared/views/auth/whoiam_view_test.dart` add these imports at the top:

```dart
import 'package:dineroo_mobile/shared/common/widgets/app_button.dart';

import '../../../helpers/window_size_helper.dart';
```

Append these tests inside `main()` after the existing test:

```dart
  testWidgets('keeps the full-width buttons on a phone', (tester) async {
    setWindowSize(tester, 390, 844);
    await tester.pumpWidget(MaterialApp(home: WhoiamView()));
    await tester.pump();

    expect(tester.getSize(find.byType(AppButton).first).width, 342);
  });

  testWidgets('centers a capped column on a wide window', (tester) async {
    setWindowSize(tester, 1200, 800);
    await tester.pumpWidget(MaterialApp(home: WhoiamView()));
    await tester.pump();

    final client = find.byType(AppButton).first;
    expect(tester.getSize(client).width, lessThanOrEqualTo(420));
    expect(tester.getCenter(client).dx, closeTo(600, 0.5));
  });

  testWidgets('scrolls instead of overflowing on a short wide window', (
    tester,
  ) async {
    setWindowSize(tester, 1200, 500);
    await tester.pumpWidget(MaterialApp(home: WhoiamView()));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('ESPACE RESTAURANT'), findsOneWidget);
  });
```

- [ ] **Step 2: Write the failing tests for LocationAccessView**

Create `test/shared/views/location/location_access_view_test.dart`:

```dart
import 'package:dineroo_mobile/shared/common/widgets/app_button.dart';
import 'package:dineroo_mobile/shared/views/location/location_access_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/window_size_helper.dart';

// The view only reads its providers when the button is tapped, so none are needed to render it.
void main() {
  group('LocationAccessView', () {
    testWidgets('keeps the full-width button on a phone', (tester) async {
      setWindowSize(tester, 390, 844);
      await tester.pumpWidget(const MaterialApp(home: LocationAccessView()));

      expect(tester.getSize(find.byType(AppButton)).width, 326);
    });

    testWidgets('centers a capped column on a wide window', (tester) async {
      setWindowSize(tester, 1200, 800);
      await tester.pumpWidget(const MaterialApp(home: LocationAccessView()));

      final button = find.byType(AppButton);
      expect(tester.getSize(button).width, lessThanOrEqualTo(420));
      expect(tester.getCenter(button).dx, closeTo(600, 0.5));
    });
  });
}
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `flutter test test/shared/views/auth/whoiam_view_test.dart test/shared/views/location/location_access_view_test.dart`
Expected: FAIL on both "centers a capped column on a wide window" tests (`Expected: a value less than or equal to <420> Actual: <1152>` for Whoiam, `<1136>` for Location). The phone and short-window tests already pass (they pin today's behavior).

- [ ] **Step 4: Center `WhoiamView`**

In `lib/shared/views/auth/whoiam_view.dart` add the import (next to the other imports):

```dart
import 'package:dineroo_mobile/shared/common/layout/adaptive_content.dart';
```

and replace the end of `build`

```dart
    return Scaffold(
      backgroundColor: AppColors.orange,
      body: SafeArea(
        child:
            needsScroll
                ? SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: screenHeight),
                    child: IntrinsicHeight(child: buildContent()),
                  ),
                )
                : buildContent(),
      ),
    );
```

with

```dart
    return Scaffold(
      backgroundColor: AppColors.orange,
      body: SafeArea(
        child: AdaptiveContent(
          maxWidth: ContentWidth.roleSelection,
          child:
              needsScroll
                  ? SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: screenHeight),
                      child: IntrinsicHeight(child: buildContent()),
                    ),
                  )
                  : buildContent(),
        ),
      ),
    );
```

- [ ] **Step 5: Center `LocationAccessView`**

In `lib/shared/views/location/location_access_view.dart` add the import:

```dart
import 'package:dineroo_mobile/shared/common/layout/adaptive_content.dart';
```

and replace the whole `build` method with the same content wrapped in `AdaptiveContent` (only the `SafeArea` child changes; the rest is the existing code, re-indented by four spaces):

```dart
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: AdaptiveContent(
            maxWidth: ContentWidth.roleSelection,
            child: Column(
              children: [
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 56,
                            child: Center(child: AppLoader()),
                          )
                          : AppButton(
                            text: 'AUTORISER LA LOCALISATION',
                            onPressed: _handleLocationPermission,
                            icon: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.location_on,
                                color: Colors.white,
                              ),
                            ),
                          ),
                ),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'DINEROO n’accède à votre position que pour vous proposer les restaurants proches.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF646982),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `dart format test/shared/views/location/location_access_view_test.dart && flutter test test/shared/views/auth/whoiam_view_test.dart test/shared/views/location`
Expected: `All tests passed!`. Do not run `dart format` on the two modified lib files or `whoiam_view_test.dart`. Check `git diff lib/shared/views/auth/whoiam_view.dart lib/shared/views/location/location_access_view.dart` shows only the wrapper, the import and the re-indentation.

- [ ] **Step 7: Commit (only if the user asked for commits)**

```bash
git add lib/shared/views/auth/whoiam_view.dart lib/shared/views/location/location_access_view.dart test/shared/views/auth/whoiam_view_test.dart test/shared/views/location/location_access_view_test.dart
git commit -m "feat(auth): center role selection and location screens on wide windows"
```

---

### Task 6: AuthLayout card on wide windows

**Files:**
- Modify: `lib/shared/views/auth/auth_layout.dart` (replace the whole file)
- Modify (append tests): `test/shared/views/auth/auth_layout_test.dart`

**Interfaces:**
- Consumes: `ContentWidth.authCard` (Task 2); `WindowSize`, `context.windowSize` (Task 1); `AppBackButton` (existing).
- Produces: `AuthLayout` keeps its constructor (`title`, `subtitle`, `subtitleWidget`, `children`, `showBackButton`). On medium and expanded windows it renders a vertically centered card of at most 480px; compact is unchanged.

- [ ] **Step 1: Write the failing tests**

In `test/shared/views/auth/auth_layout_test.dart` add the import:

```dart
import '../../../helpers/window_size_helper.dart';
```

Append these tests inside the existing `group('AuthLayout', ...)` after the last test:

```dart
    testWidgets('keeps the full-width sheet on a phone', (tester) async {
      setWindowSize(tester, 390, 844);
      await tester.pumpWidget(
        MaterialApp(
          home: AuthLayout(
            title: 'Test',
            children: const [
              SizedBox(key: Key('probe'), width: double.infinity, height: 10),
            ],
          ),
        ),
      );
      await tester.pump();

      // 390 minus the 20px horizontal padding on each side.
      expect(tester.getSize(find.byKey(const Key('probe'))).width, 350);
    });

    testWidgets('renders a centered card of at most 480px on a wide window', (
      tester,
    ) async {
      setWindowSize(tester, 1200, 800);
      await tester.pumpWidget(
        MaterialApp(
          home: AuthLayout(
            title: 'Test',
            children: const [
              SizedBox(key: Key('probe'), width: double.infinity, height: 10),
            ],
          ),
        ),
      );
      await tester.pump();

      final probe = find.byKey(const Key('probe'));
      expect(tester.getSize(probe).width, lessThanOrEqualTo(480));
      expect(tester.getCenter(probe).dx, closeTo(600, 0.5));
    });

    testWidgets('scrolls a tall form on a short wide window without overflow', (
      tester,
    ) async {
      setWindowSize(tester, 1200, 500);
      await tester.pumpWidget(
        MaterialApp(
          home: AuthLayout(
            title: 'Test',
            children: const [SizedBox(height: 1200, child: Text('tall'))],
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('tall'), findsOneWidget);
    });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/shared/views/auth/auth_layout_test.dart`
Expected: FAIL on "renders a centered card of at most 480px on a wide window" (`Expected: a value less than or equal to <480> Actual: <1160>`). The phone test and the existing three tests pass; the short-window test may already pass because the current layout scrolls its body.

- [ ] **Step 3: Replace `AuthLayout`**

Replace the full contents of `lib/shared/views/auth/auth_layout.dart` with:

```dart
import 'package:dineroo_mobile/shared/common/layout/adaptive_content.dart';
import 'package:dineroo_mobile/shared/common/layout/window_size.dart';
import 'package:flutter/material.dart';
import '../../common/widgets/app_back_button.dart';

class AuthLayout extends StatelessWidget {
  static const Color _background = Color(0xFF0F0F2D);

  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final bool showBackButton;
  final List<Widget> children;

  const AuthLayout({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    required this.children,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = context.windowSize == WindowSize.compact;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: isCompact ? _buildCompactBody() : _buildCardBody(),
      ),
    );
  }

  Widget _buildCompactBody() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 40.0,
            ),
            child: SingleChildScrollView(child: Column(children: children)),
          ),
        ),
      ],
    );
  }

  /// Medium and expanded windows: a vertically centered card that scrolls when taller than the
  /// window.
  Widget _buildCardBody() {
    return LayoutBuilder(
      builder:
          (context, viewport) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: viewport.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: ContentWidth.authCard,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 40.0,
                          ),
                          child: Column(children: children),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 180,
      width: double.infinity,
      color: _background,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Stack(
          children: [
            if (showBackButton)
              const Align(
                alignment: Alignment.topLeft,
                child: AppBackButton(backgroundColor: Colors.white),
              ),
            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (subtitleWidget != null)
                      subtitleWidget!
                    else if (subtitle != null)
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/shared/views/auth`
Expected: `All tests passed!` (all auth tests, including login, sign-up, verify-code and forgot-PIN tests that use `AuthLayout`). Do not run `dart format` on `auth_layout.dart` or `auth_layout_test.dart`.

- [ ] **Step 5: Look at it in a browser**

Run `make web`, open `http://localhost:3000`, choose "JE SUIS UN CLIENT" to reach the login screen, and resize the window to about 390, 820 and 1440 px wide. Expected: full-width sheet at 390; a rounded white card centered on the dark background at 820 and 1440 (dark header above it). If the card looks wrong, adjust padding and radius in `_buildCardBody` only, keeping the tests green.

- [ ] **Step 6: Commit (only if the user asked for commits)**

```bash
git add lib/shared/views/auth/auth_layout.dart test/shared/views/auth/auth_layout_test.dart
git commit -m "feat(auth): render auth screens as a centered card on wide windows"
```

---

### Task 7: Mouse and trackpad drag scrolling

**Files:**
- Create: `lib/shared/common/layout/app_scroll_behavior.dart`
- Modify: `lib/main.dart` (import; `MaterialApp`)
- Test: `test/shared/common/layout/app_scroll_behavior_test.dart`
- Modify (append test): `test/main_test.dart`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `AppScrollBehavior` (const constructor, extends `MaterialScrollBehavior`) whose `dragDevices` also contains `PointerDeviceKind.mouse`, `trackpad` and `stylus`; `MaterialApp.scrollBehavior` in `DinerooApp` is an `AppScrollBehavior`.

- [ ] **Step 1: Write the failing tests**

Create `test/shared/common/layout/app_scroll_behavior_test.dart`:

```dart
import 'package:dineroo_mobile/shared/common/layout/app_scroll_behavior.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _list(ScrollController controller, {ScrollBehavior? behavior}) {
  return MaterialApp(
    scrollBehavior: behavior,
    home: Scaffold(
      body: ListView(
        controller: controller,
        children: [
          for (var i = 0; i < 30; i++) SizedBox(height: 100, child: Text('row $i')),
        ],
      ),
    ),
  );
}

Future<void> _dragWithMouse(WidgetTester tester) async {
  final gesture = await tester.startGesture(
    const Offset(200, 300),
    kind: PointerDeviceKind.mouse,
  );
  await gesture.moveBy(const Offset(0, -200));
  await gesture.up();
  await tester.pump();
}

void main() {
  group('AppScrollBehavior', () {
    test('accepts mouse, trackpad and stylus drags', () {
      const behavior = AppScrollBehavior();

      expect(behavior.dragDevices, contains(PointerDeviceKind.mouse));
      expect(behavior.dragDevices, contains(PointerDeviceKind.trackpad));
      expect(behavior.dragDevices, contains(PointerDeviceKind.stylus));
      expect(behavior.dragDevices, contains(PointerDeviceKind.touch));
    });

    testWidgets('scrolls a list dragged with a mouse', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _list(controller, behavior: const AppScrollBehavior()),
      );

      await _dragWithMouse(tester);

      expect(controller.offset, greaterThan(0));
    });

    testWidgets('control: the default behavior ignores a mouse drag', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_list(controller));

      await _dragWithMouse(tester);

      expect(controller.offset, 0);
    });
  });
}
```

In `test/main_test.dart` add the import

```dart
import 'package:dineroo_mobile/shared/common/layout/app_scroll_behavior.dart';
```

and append inside `main()` after the existing `testWidgets`:

```dart
  testWidgets('DinerooApp lets a mouse drag scroll lists', (tester) async {
    await tester.pumpWidget(const app.DinerooApp());
    await tester.pump();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(materialApp.scrollBehavior, isA<AppScrollBehavior>());
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/shared/common/layout/app_scroll_behavior_test.dart test/main_test.dart`
Expected: FAIL to compile with `Target of URI doesn't exist: 'package:dineroo_mobile/shared/common/layout/app_scroll_behavior.dart'`.

- [ ] **Step 3: Write the implementation**

Create `lib/shared/common/layout/app_scroll_behavior.dart`:

```dart
import 'package:flutter/material.dart';

/// Flutter ignores mouse drags on scrollables by default, which breaks pull-to-refresh and
/// horizontal carousels in a desktop browser. Desktop scrollbars come from [MaterialScrollBehavior].
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    ...super.dragDevices,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}
```

- [ ] **Step 4: Wire it into `MaterialApp`**

In `lib/main.dart` add the import (next to the other `shared/common` imports):

```dart
import 'package:dineroo_mobile/shared/common/layout/app_scroll_behavior.dart';
```

and in the `MaterialApp(...)` add the argument right after `title: 'Dineroo',`:

```dart
            scrollBehavior: const AppScrollBehavior(),
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `dart format lib/shared/common/layout/app_scroll_behavior.dart test/shared/common/layout/app_scroll_behavior_test.dart && flutter test test/shared/common/layout/app_scroll_behavior_test.dart test/main_test.dart`
Expected: `All tests passed!`. Do not run `dart format` on `main.dart` or `main_test.dart`; `git diff lib/main.dart test/main_test.dart` must show only the lines added above.

- [ ] **Step 6: Commit (only if the user asked for commits)**

```bash
git add lib/shared/common/layout/app_scroll_behavior.dart lib/main.dart test/shared/common/layout/app_scroll_behavior_test.dart test/main_test.dart
git commit -m "feat(web): allow mouse and trackpad drag scrolling"
```

---

### Task 8: Extract the app theme and cap dialog width

**Files:**
- Create: `lib/shared/common/config/app_theme.dart`
- Modify: `lib/main.dart` (import; the inline `theme: ThemeData(...)`)
- Test: `test/shared/common/config/app_theme_test.dart`

**Interfaces:**
- Consumes: `setWindowSize` (Task 1); existing `AppDialog` (`lib/shared/common/widgets/app_dialog.dart`).
- Produces: `ThemeData buildAppTheme()` returning the app theme, with `dialogTheme.constraints` of `minWidth: 280, maxWidth: 560`. Bottom sheets keep the Material 3 default (640px, verified).

- [ ] **Step 1: Write the failing tests**

Create `test/shared/common/config/app_theme_test.dart`:

```dart
import 'package:dineroo_mobile/shared/common/config/app_theme.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/window_size_helper.dart';

final _longMessage = List.filled(
  40,
  'Un message de dialogue assez long pour s\'étendre sur toute la largeur.',
).join(' ');

Future<void> _openFromButton(
  WidgetTester tester,
  void Function(BuildContext context) open,
) async {
  setWindowSize(tester, 1200, 800);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Builder(
        builder:
            (context) => Scaffold(
              body: TextButton(
                onPressed: () => open(context),
                child: const Text('open'),
              ),
            ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('buildAppTheme', () {
    testWidgets('caps dialogs at 560px on a wide window', (tester) async {
      await _openFromButton(
        tester,
        (context) => showDialog<void>(
          context: context,
          builder: (_) => AppDialog(title: 'Titre', message: _longMessage),
        ),
      );

      expect(
        tester.getSize(find.byType(AlertDialog)).width,
        lessThanOrEqualTo(560),
      );
    });

    testWidgets('keeps bottom sheets within 640px on a wide window', (
      tester,
    ) async {
      await _openFromButton(
        tester,
        (context) => showModalBottomSheet<void>(
          context: context,
          builder: (_) => const SizedBox(height: 200, child: Text('sheet')),
        ),
      );

      expect(
        tester.getSize(find.byType(BottomSheet)).width,
        lessThanOrEqualTo(640),
      );
    });

    test('keeps the existing brand styling', () {
      final theme = buildAppTheme();

      expect(theme.textTheme.bodyMedium?.fontFamily, 'Montserrat');
      expect(theme.scaffoldBackgroundColor, Colors.white);
      expect(theme.appBarTheme.backgroundColor, Colors.white);
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/shared/common/config/app_theme_test.dart`
Expected: FAIL to compile with `Target of URI doesn't exist: 'package:dineroo_mobile/shared/common/config/app_theme.dart'`.

- [ ] **Step 3: Extract the theme unchanged**

Create `lib/shared/common/config/app_theme.dart` (an exact copy of the inline theme, no dialog cap yet):

```dart
import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    fontFamily: 'Montserrat',
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: Colors.deepOrange,
      unselectedLabelColor: Colors.grey,
      indicatorColor: Colors.deepOrange,
    ),
  );
}
```

In `lib/main.dart` add the import:

```dart
import 'package:dineroo_mobile/shared/common/config/app_theme.dart';
```

and replace the inline theme

```dart
            theme: ThemeData(
              fontFamily: 'Montserrat',
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
              ),
              tabBarTheme: const TabBarThemeData(
                labelColor: Colors.deepOrange,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.deepOrange,
              ),
            ),
```

with

```dart
            theme: buildAppTheme(),
```

- [ ] **Step 4: Run the tests to verify the dialog test fails for the right reason**

Run: `flutter test test/shared/common/config/app_theme_test.dart`
Expected: the dialog test FAILS with `Expected: a value less than or equal to <560> Actual: <1120>`; the sheet test and the brand-styling test PASS (the sheet cap is the verified Material 3 default).

- [ ] **Step 5: Add the dialog cap**

In `lib/shared/common/config/app_theme.dart` add this argument after `tabBarTheme`:

```dart
    // Material 3 dialogs have no maximum width by default, so long messages stretch across a
    // desktop window.
    dialogTheme: const DialogThemeData(
      constraints: BoxConstraints(minWidth: 280, maxWidth: 560),
    ),
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `dart format lib/shared/common/config/app_theme.dart test/shared/common/config/app_theme_test.dart && flutter test test/shared/common/config/app_theme_test.dart test/main_test.dart`
Expected: `All tests passed!`. `git diff lib/main.dart` must show only the Task 7 and Task 8 edits.

- [ ] **Step 7: Commit (only if the user asked for commits)**

```bash
git add lib/shared/common/config/app_theme.dart lib/main.dart test/shared/common/config/app_theme_test.dart
git commit -m "feat(theme): extract app theme and cap dialog width at 560px"
```

---

### Task 9: Full verification and handoff

**Files:**
- Modify: `docs/superpowers/specs/2026-10-12-adaptive-shell-design.md` (status line only)

**Interfaces:** none.

- [ ] **Step 1: Run the full VM suite and the analyzer**

Run: `flutter test --concurrency=4 --dart-define=DINEROO_SILENCE_LOGS=true`
Expected: `All tests passed!` with no failures (the count is above the earlier 724).

Run: `flutter analyze`
Expected: `No issues found!`.

- [ ] **Step 2: Run the browser tests exactly as CI does**

Run: `flutter test --platform chrome $(grep -rl "@TestOn('browser')" test)`
Expected: `All tests passed!` (8 tests from sub-project 0; this slice adds none).

- [ ] **Step 3: Build the release web app**

Run: `flutter build web --release --no-wasm-dry-run && test -f build/web/assets/.env && echo ENV-OK`
Expected: `Built build/web` and `ENV-OK`.

- [ ] **Step 4: Check the pre-login screens at three widths in Chrome**

Run `make web`, then in Chrome DevTools (device toolbar, responsive mode) or by resizing the window, check the role-selection screen and the login screen at 390, 820 and 1440 px wide:
- 390: identical to before (full-width buttons, full-width sheet).
- 820 and 1440: role-selection column about 420px wide and centered, login as a centered rounded card of at most 480px, no overflow, no console errors.

If a DevTools-driven screenshot script is available in the session scratchpad (`cdp-run.mjs`), `node cdp-run.mjs http://localhost:<port>/ <outPrefix> 8000 <width> <height>` against a served `build/web` records the same checks. Stop any static server you started by port (`lsof -ti tcp:<port> -sTCP:LISTEN | xargs kill`).

- [ ] **Step 5: Ask the user to check the navigation shell with a real account**

The navigation rail sits behind login and cannot be shown without a backend. Ask the user to log in on `make web` at 1440 px (extended rail for customer, driver and manager), at about 768 px (labelled rail) and at 390 px (bottom bar), and to check the driver "hide menus" state and pull-to-refresh with the mouse. Report what they see; do not claim the shell works on web from the widget tests alone.

- [ ] **Step 6: Update the spec status**

In `docs/superpowers/specs/2026-10-12-adaptive-shell-design.md` change the status line

```
Status: design approved by the user on 2026-10-12.
```

to

```
Status: implemented on branch feat/web-support-foundation; navigation shell still to be checked by the user with a real account.
```

(keeping the remainder of that line unchanged).

- [ ] **Step 7: Final diff review**

Run: `git status --short` and `git diff --stat`.
Expected: only the files listed in the File Structure table plus the sub-project 0 files, no formatter churn in existing files, no stray debug output. Report the result to the user and ask whether to commit.
