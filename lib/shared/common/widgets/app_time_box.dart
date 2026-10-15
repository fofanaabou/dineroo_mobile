import 'package:flutter/material.dart';

class AppTimeBox extends StatelessWidget {
  final TimeOfDay? time;
  final VoidCallback? onTap;
  final double height;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final BorderRadius borderRadius;
  final TextStyle? textStyle;

  const AppTimeBox({
    super.key,
    required this.time,
    this.onTap,
    this.height = 42.0,
    this.backgroundColor = const Color(0xFFF8F8F8),
    this.borderColor = const Color(0xFFD0D0D0),
    this.borderWidth = 1.2,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: borderRadius,
      onTap: onTap,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Text(
          time != null ? time!.format(context) : '--:--',
          style:
              textStyle ??
              const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.2,
                color: Colors.black,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
