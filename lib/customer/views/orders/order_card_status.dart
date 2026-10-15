import 'package:dineroo_mobile/shared/enums/order_status.dart';
import 'package:flutter/material.dart';

class OrderCardStatus extends StatelessWidget {
  final OrderStatus status;

  const OrderCardStatus({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    if (!status.isHistory) {
      return const SizedBox();
    }

    return Text(
      status.label,
      style: TextStyle(color: status.color, fontWeight: FontWeight.bold),
    );
  }
}
