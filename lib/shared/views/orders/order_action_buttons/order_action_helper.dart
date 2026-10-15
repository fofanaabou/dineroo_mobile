import 'package:dineroo_mobile/manager/view_models/orders/manager_order_list_view_model.dart';
import 'package:dineroo_mobile/shared/enums/order_status.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

String toRestaurantStatus(OrderStatus status) {
  switch (status) {
    case OrderStatus.accepted:
      return 'ACCEPTED';
    case OrderStatus.rejected:
      return 'REJECTED';
    case OrderStatus.preparing:
      return 'PREPARING';
    case OrderStatus.readyForPickup:
      return 'READY';
    case OrderStatus.pickedUp:
      return 'PICKED_UP';
    case OrderStatus.delivered:
      return 'COMPLETED';
    case OrderStatus.completed:
      return 'COMPLETED';
    case OrderStatus.canceled:
      return 'CANCELED';
    default:
      return status.apiValue;
  }
}

void applyLocalStatusUpdate(
  BuildContext context,
  String orderId,
  OrderStatus status,
) {
  try {
    context
        .read<ManagerOrderListViewModel>()
        .applyLocalStatusUpdate(orderId: orderId, status: status);
  } on ProviderNotFoundException {
    // no provider in detail routes
  }
}
