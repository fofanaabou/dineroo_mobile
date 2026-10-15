import 'package:dineroo_mobile/shared/common/colors.dart';
import 'package:flutter/material.dart';

class AppAddButton extends StatelessWidget {
  final VoidCallback? onTap;
  final double size;

  const AppAddButton({super.key, required this.onTap, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: disabled ? Colors.grey.shade200 : Colors.white,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        elevation: disabled ? 0 : 2,
        shadowColor: Colors.black26,
        child: InkWell(
          onTap: onTap,
          child: Icon(
            Icons.add_rounded,
            size: size * 0.56,
            color: disabled ? Colors.grey.shade400 : AppColors.orange,
          ),
        ),
      ),
    );
  }
}
