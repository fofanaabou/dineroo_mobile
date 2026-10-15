import 'package:dineroo_mobile/shared/common/helpers/price_helper.dart';
import 'package:flutter/material.dart';

class MenuPriceQuantity extends StatelessWidget {
  final double unitPrice;

  const MenuPriceQuantity({super.key, required this.unitPrice});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE0CC)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Colors.deepOrange,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.restaurant_menu, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prix de base du menu',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                SizedBox(height: 2),
                Text(
                  'Les suppléments s’ajoutent selon tes choix',
                  style: TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            formatPrice(unitPrice),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF5F5448),
            ),
          ),
        ],
      ),
    );
  }
}
