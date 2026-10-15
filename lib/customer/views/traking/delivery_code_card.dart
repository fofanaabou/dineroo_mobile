import 'package:dineroo_mobile/shared/enums/order_status.dart';
import 'package:flutter/material.dart';

class DeliveryCodeCard extends StatelessWidget {
  final bool compact;
  final OrderStatus status;
  final String deliveryContactPhoneNumber;

  const DeliveryCodeCard({
    super.key,
    this.compact = false,
    required this.status,
    required this.deliveryContactPhoneNumber,
  });

  String get _deliveryCode {
    if (deliveryContactPhoneNumber.length < 4) return '----';
    return deliveryContactPhoneNumber.substring(
      deliveryContactPhoneNumber.length - 4,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (status.isFailure) {
      return const SizedBox.shrink();
    }

    final deliveryCode = _deliveryCode;

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFF7643),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              deliveryCode,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Container(
        key: const ValueKey('deliveryCode'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF2F0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Code à donner au livreur',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFF7643),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              deliveryCode,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
