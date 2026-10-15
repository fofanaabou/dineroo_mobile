import 'package:flutter/material.dart';

class AppSnackbar {
  static const double _defaultMargin = 16;

  static void show(
    BuildContext context,
    String message, {
    Color backgroundColor = Colors.black87,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    double bottomMargin = _defaultMargin,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final horizontalMargin =
        isLandscape ? mediaQuery.size.width * 0.25 : _defaultMargin;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.fromLTRB(
          horizontalMargin,
          _defaultMargin,
          horizontalMargin,
          bottomMargin,
        ),
      ),
    );
  }

  static void success(
    BuildContext context,
    String message, {
    double bottomMargin = _defaultMargin,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message,
      backgroundColor: Colors.green,
      bottomMargin: bottomMargin,
      duration: duration,
    );
  }

  static void error(
    BuildContext context,
    String message, {
    double bottomMargin = _defaultMargin,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message,
      backgroundColor: Colors.redAccent,
      bottomMargin: bottomMargin,
      duration: duration,
    );
  }

  static void warning(
    BuildContext context,
    String message, {
    double bottomMargin = _defaultMargin,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message,
      backgroundColor: Colors.orange,
      bottomMargin: bottomMargin,
      duration: duration,
    );
  }
}
