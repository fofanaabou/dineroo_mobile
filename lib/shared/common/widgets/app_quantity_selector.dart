import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/common/colors.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_button_icon.dart';

class AppQuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback? onDelete;
  final bool isDisabled;
  final double size;

  const AppQuantitySelector({
    super.key,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    this.onDelete,
    this.isDisabled = false,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildLeftButton(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '$quantity',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        _buildRightButton(),
      ],
    );
  }

  Widget _buildLeftButton() {
    return AppButtonIcon(
      icon: Icons.remove,
      onTap: onRemove,
      backgroundColor: AppColors.orange.withValues(alpha: 0.12),
      iconColor: AppColors.orange,
      isDisabled: isDisabled,
      size: size,
    );
  }

  Widget _buildRightButton() {
    return AppButtonIcon(
      icon: Icons.add,
      onTap: onAdd,
      backgroundColor: AppColors.orange,
      iconColor: Colors.white,
      isDisabled: isDisabled,
      size: size,
    );
  }
}
