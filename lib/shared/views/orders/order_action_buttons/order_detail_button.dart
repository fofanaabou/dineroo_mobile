import 'package:dineroo_mobile/manager/enums/order_source.dart';
import 'package:dineroo_mobile/shared/common/helpers/navigation_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_button.dart';
import 'package:dineroo_mobile/shared/views/orders/order_detail_view.dart';
import 'package:flutter/material.dart';

class OrderDetailButton extends StatelessWidget {
  final dynamic orderId;
  final OrderSource? source;
  final bool isSmall;
  final VoidCallback? onTap;

  const OrderDetailButton({
    super.key,
    required this.orderId,
    this.source,
    this.isSmall = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton(
      text: 'Détail',
      backgroundColor: Colors.grey.shade300,
      textColor: Colors.black,
      isSmall: isSmall,
      onPressed: () {
        if (onTap != null) {
          onTap!();
        } else {
          navigateTo(
            context,
            OrderDetailView(orderId: orderId, source: source),
          );
        }
      },
    );
  }
}
