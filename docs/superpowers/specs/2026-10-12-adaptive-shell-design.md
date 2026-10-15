# Adaptive shell for web and tablet (first slice)

Status: implemented on branch feat/web-support-foundation (uncommitted); the navigation shell is still to be checked by the user with a real account. Part of the web and tablet initiative (plan: `~/.claude/plans/this-project-is-intended-sequential-tower.md`, sub-project 2).

## Problem

On web the app is the phone layout stretched edge to edge: full-width buttons, a single column and a bottom navigation bar on a 1440px window. Verified with headless Chrome screenshots at 1280px (role-selection screen) and 390px (correct). Mouse drag does not scroll lists, so pull-to-refresh and horizontal carousels do not work with a mouse.

## Goal

Make the shared shell adaptive so that every role (customer, driver, manager) gets a web and tablet appropriate navigation and a sensible content width, while phones stay pixel-identical.

Success looks like:
- Compact (< 600px): identical to today.
- Medium and expanded: side navigation instead of the bottom bar, auth and role-selection screens as centered content instead of stretched, lists scrollable with a mouse.

## Decisions (from the user)

- UX direction: adaptive layouts per size class, not a single centered phone column and not separate web widget trees.
- Start with the shared shell (navigation, auth, role selection), then customer, then manager in later slices.
- Tablets in portrait (768px) get the side rail as well.

## Non-goals for this slice

- Customer screens (restaurant grid, cart, checkout) and manager screens (order deck, catalog): next slices.
- Unlocking portrait on native tablets (`main.dart` orientation lock, `AndroidManifest.xml`, `Info.plist`): stays locked until the inner layouts are adapted.
- Enter-to-submit and autofill on the login and OTP forms: next slice.
- Routing and URLs (Navigator 1.0 stays).
- Customer payment, uploads and push on web (sub-projects 1 and 3).

## Design

### 1. Window size classes
`lib/shared/common/layout/window_size.dart`
- `enum WindowSize { compact, medium, expanded }` with `WindowSize.fromWidth(double)`: compact under 600, medium from 600 to under 840, expanded from 840.
- `extension on BuildContext`: `windowSize`, reading `MediaQuery.sizeOf(context).width`.
- The width-based thresholds are named constants. Every adaptive widget uses this single helper.

### 2. Adaptive navigation
`lib/shared/views/adaptive_nav_scaffold.dart`

```dart
AdaptiveNavScaffold({
  required int currentIndex,
  required ValueChanged<int> onSelected,
  required List<BottomNavigationBarItem> items,
  required Widget body,
  bool showNavigation = true,
})
```
- Compact: `Scaffold` with the existing `BottomNavBar` (unchanged, `lib/shared/views/bottom_nav_bar.dart`).
- Medium: `Scaffold` whose body is a `Row`: `NavigationRail` (labels shown under icons), a `VerticalDivider`, and the body in an `Expanded`.
- Expanded: same, with the rail extended (icon and label side by side).
- Rail colors match the bottom bar (selected `Colors.deepOrange`, unselected `Colors.grey`, white background).
- Destinations are built from the same `BottomNavigationBarItem` list the role main views already pass (`icon`, `activeIcon`, `label`), so `CustomerMainView`, `DriverMainView` and `ManagerMainView` need no changes.
- `showNavigation: false` hides the bottom bar and the rail (replaces `hideBottomNav`).
- `NavigationRail` needs at least two destinations; implementation must confirm every role has two or more.

Adopted by both shells:
- `BaseMainView` (`lib/shared/views/base_main_view.dart`): replaces its `Scaffold` with `AdaptiveNavScaffold`, passing `showNavigation: !hideBottomNav`. The `PopScope` and the inherited navigation scope stay as they are.
- `BaseMainWrapper` (`lib/shared/views/base_main_wrapper.dart`): replaces its `Scaffold` with `AdaptiveNavScaffold`. `_handleNavTap` (replace all with the role's main view) is unchanged.

### 3. Content that stops stretching
`lib/shared/common/layout/adaptive_content.dart`: `AdaptiveContent({required double maxWidth, required Widget child})` centers the child with a maximum width. Maximum widths are named constants.

- `WhoiamView` (`lib/shared/views/auth/whoiam_view.dart`): on medium and expanded the content column is centered with a 420px maximum, background stays full-bleed orange. Compact unchanged.
- `LocationAccessView` (`lib/shared/views/location/location_access_view.dart`): same 420px column.
- `AuthLayout` (`lib/shared/views/auth/auth_layout.dart`): on medium and expanded, a vertically centered card of at most 480px (all corners rounded, scrolls when taller than the window) on the existing dark background. Compact unchanged. Exact card visuals are settled in implementation against screenshots.
- Dialogs and bottom sheets: capped at 560px through `ThemeData` only where the Material 3 defaults do not already cap them (bottom sheets default to 640px).

### 4. Mouse and trackpad scrolling
`lib/shared/common/layout/app_scroll_behavior.dart`: `AppScrollBehavior extends MaterialScrollBehavior` adds mouse, trackpad and stylus to `dragDevices`. Set once as `scrollBehavior` on `MaterialApp` in `lib/main.dart`. Desktop scrollbars come from `MaterialScrollBehavior`.

## Behaviour by size

| Width | Navigation | Auth / role screens |
|---|---|---|
| < 600 | bottom bar (today) | today |
| 600-839 | rail with labels under icons | centered column / card |
| >= 840 | extended rail | centered column / card |

A visible side effect: iPad and Android tablets in portrait (768px) show the rail immediately. The inner screens are still the phone layouts until later slices.

## Error handling and edge cases
- Window resized across a breakpoint: widgets rebuild from `MediaQuery`; the selected tab and the lazily built tab screens live in `BaseMainView` state and are preserved.
- Fewer than two nav items: assert in `AdaptiveNavScaffold` with a clear message, because `NavigationRail` cannot render it.
- Very short windows: auth card and role column scroll; no overflow.

## Testing
Widget tests set `tester.view.physicalSize` and `devicePixelRatio = 1`, and reset in `addTearDown`.

- `AdaptiveNavScaffold` at 390 (bottom bar, no rail), 700 (rail, labels, not extended, no bottom bar) and 1200 (extended rail); tapping a destination calls `onSelected`; `showNavigation: false` shows neither.
- `WindowSize.fromWidth` at the boundary values 599, 600, 839 and 840.
- `WhoiamView` and `AuthLayout` at 390 (same structure as today) and 1200 (content within the maximum width, no overflow exception).
- `AppScrollBehavior.dragDevices` contains mouse, trackpad and stylus.
- Existing suite (724 tests) stays green; `flutter analyze` clean.
- Browser tests where web-only behaviour matters are tagged `@TestOn('browser')` and run by `ci-web.yml`.

## Verification
- DevTools-driven Chrome screenshots at 390, 820 and 1440px of the pre-login screens (role selection, login).
- The navigation shell sits behind login and cannot be shown without a backend, so it is covered by widget tests and a manual check by the user with a real account on `make web` (and an iPad or Android tablet).

## Risks
- Rail on tablets before inner layouts are adapted: accepted (user decision), documented above.
- `BaseMainWrapper` rebuilds the main view on every tab tap (existing behaviour); unchanged here.
- Material 3 rail and bottom bar differ slightly in styling; colors are set explicitly to match.
