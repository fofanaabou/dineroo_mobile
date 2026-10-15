import 'package:flutter/material.dart';

class AppLoader extends StatelessWidget {
  final double size;
  final Color color;
  final double? strokeWidth;

  const AppLoader({
    super.key,
    this.size = 48.0,
    this.color = Colors.deepOrange,
    this.strokeWidth = 2.4,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
