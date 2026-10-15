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
    // Material 3 dialogs have no maximum width by default, so long messages stretch across a
    // desktop window.
    dialogTheme: const DialogThemeData(
      constraints: BoxConstraints(minWidth: 280, maxWidth: 560),
    ),
  );
}
