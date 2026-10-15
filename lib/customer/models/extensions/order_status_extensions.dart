import 'package:dineroo_mobile/shared/enums/order_status.dart';

extension CustomerOrderStatusExtensions on OrderStatus {
  bool get isCustomerHistory => isDeliveredOrCompleted || isFailure;

  bool get isCustomerOngoing => !isCustomerHistory;
}
