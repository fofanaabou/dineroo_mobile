import 'package:dineroo_mobile/shared/common/widgets/app_button.dart';
import 'package:flutter/material.dart';

class OrderTrackButton extends StatelessWidget {
  final dynamic orderId;
  final bool isSmall;
  final VoidCallback? onTap;

  const OrderTrackButton({
    super.key,
    required this.orderId,
    this.isSmall = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton(text: 'Suivre', isSmall: isSmall, onPressed: onTap);
  }
}
