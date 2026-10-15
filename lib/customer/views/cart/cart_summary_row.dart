import 'package:dineroo_mobile/shared/common/helpers/price_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:flutter/material.dart';

class CartSummaryRow extends StatelessWidget {
  final String label;
  final double? amount;
  final bool isLoading;

  const CartSummaryRow({
    super.key,
    required this.label,
    required this.amount,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF696969)),
          ),
          if (isLoading && amount == null)
            const AppLoader(size: 12, strokeWidth: 2)
          else
            Text(
              amount == null ? '-' : formatPrice(amount!),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF040404),
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
