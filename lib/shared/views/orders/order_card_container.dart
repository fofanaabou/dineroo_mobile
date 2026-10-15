import 'package:flutter/material.dart';

class OrderCardContainer extends StatelessWidget {
  final Widget child;

  const OrderCardContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: 400,
          margin: const EdgeInsets.only(bottom: 5),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: const Color(0xFFFF7622), width: 2),
          ),
          child: child,
        ),
      ),
    );
  }
}
