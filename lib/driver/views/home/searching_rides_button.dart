import 'dart:math' as math;
import 'package:flutter/material.dart';

class SearchingRidesButton extends StatelessWidget {
  final AnimationController controller;

  const SearchingRidesButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: controller,
            builder: (_, child) {
              return Transform.rotate(
                angle: controller.value * math.pi,
                child: child,
              );
            },
            child: Image.asset(
              'assets/images/app_spinner.png',
              width: 23,
              height: 27,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                "Recherche de courses",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
