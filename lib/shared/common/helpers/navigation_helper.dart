import 'package:flutter/material.dart';

/// Pushes a new screen onto the navigation stack.
/// Allows the user to go back to the previous screen.
Future<T?> navigateTo<T>(BuildContext context, Widget screen) {
  return Navigator.of(context).push<T>(buildFadeRoute(screen));
}

/// Replaces the current screen with a new one.
/// Removes only the current screen from the stack.
void replaceWith(BuildContext context, Widget screen) {
  Navigator.of(context).pushReplacement(buildFadeRoute(screen));
}

/// Pushes a screen and removes the last [count] screens from the stack.
void replaceLastScreens(BuildContext context, Widget screen, int count) {
  int popped = 0;
  Navigator.of(context).popUntil((route) {
    return popped++ >= count;
  });
  Navigator.of(context).push(buildFadeRoute(screen));
}

/// Replaces all screens with a new one.
/// Clears the entire navigation stack.
void replaceAll(BuildContext context, Widget screen) {
  Navigator.of(
    context,
  ).pushAndRemoveUntil(buildFadeRoute(screen), (route) => false);
}

/// Returns a [PageRouteBuilder] with fade transition.
PageRouteBuilder<T> buildFadeRoute<T>(Widget screen) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => screen,
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 250),
  );
}
