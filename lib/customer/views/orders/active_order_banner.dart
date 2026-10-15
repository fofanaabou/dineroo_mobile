import 'package:dineroo_mobile/customer/views/customer_main_view.dart';
import 'package:dineroo_mobile/shared/enums/main_view_tabs.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_text_button.dart';
import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/common/helpers/navigation_helper.dart';

class ActiveOrderBanner extends StatelessWidget {
  const ActiveOrderBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF7643)),
      ),
      child: Row(
        children: [
          const Icon(Icons.route, color: Color(0xFFFF7643), size: 32),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suivre ma commande',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Consultez l\'avancement de votre commande.',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.deepOrange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: AppTextButton(
              text: 'Suivre',
              color: Colors.white,
              onPressed: () => replaceAll(
                context,
                CustomerMainView(
                  initialTab: CustomerMainViewTab.orders,
                  initialOrdersTabIndex: 0,
                ),
              ),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
