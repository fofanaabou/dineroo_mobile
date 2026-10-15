import 'package:dineroo_mobile/shared/services/user/user_call_service.dart';
import 'package:flutter/material.dart';

class AppCallButton extends StatelessWidget {
  final String phoneNumber;
  final double size;
  final Color color;

  const AppCallButton({
    super.key,
    required this.phoneNumber,
    this.size = 40,
    this.color = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhone = phoneNumber.trim().isNotEmpty;

    return InkWell(
      onTap:
          hasPhone
              ? () => UserCallService.makeCall(context, phoneNumber)
              : null,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: hasPhone ? color : Colors.grey.shade400,
        ),
        child: Icon(Icons.call, color: Colors.white, size: size * 0.5),
      ),
    );
  }
}
