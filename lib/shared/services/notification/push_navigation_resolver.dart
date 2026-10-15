import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:dineroo_mobile/customer/views/customer_main_view.dart';
import 'package:dineroo_mobile/customer/views/traking/tracking_map_view.dart';
import 'package:dineroo_mobile/customer/views/wallet/customer_wallet_view.dart';
import 'package:dineroo_mobile/driver/views/driver_main_view.dart';
import 'package:dineroo_mobile/manager/views/manager_main_view.dart';
import 'package:dineroo_mobile/shared/enums/main_view_tabs.dart';
import 'package:dineroo_mobile/shared/enums/push_notification_type.dart';
import 'package:dineroo_mobile/shared/enums/user_role.dart';
import 'package:dineroo_mobile/shared/models/domain/push_notification_payload.dart';
import 'package:dineroo_mobile/shared/views/auth/login_view.dart';
import 'package:flutter/widgets.dart';

class PushNavigationResolver {
  const PushNavigationResolver();

  Widget? resolve({
    required User? currentUser,
    required PushNotificationPayload payload,
  }) {
    if (payload.type == PushNotificationType.courierDecision) {
      return const LoginView(selectedRole: UserRole.driver);
    }

    return switch (currentUser?.userRoleEnum) {
      UserRole.customer => _customerScreenForPush(payload: payload),
      UserRole.driver => _driverScreenForPush(payload: payload),
      UserRole.restaurantManager => _managerScreenForPush(payload: payload),
      _ => null,
    };
  }

  Widget? _customerScreenForPush({required PushNotificationPayload payload}) {
    const trackingViewTypes = {
      PushNotificationType.orderAccepted,
      PushNotificationType.orderPreparing,
      PushNotificationType.orderReady,
      PushNotificationType.deliveryAssigned,
    };
    const historyTabTypes = {
      PushNotificationType.orderRejected,
      PushNotificationType.orderDelivered,
    };
    const walletTypes = {
      PushNotificationType.walletRecredited,
      PushNotificationType.walletCredited,
      PushNotificationType.walletDebited,
    };

    if (payload.orderId != null &&
        payload.orderId!.isNotEmpty &&
        trackingViewTypes.contains(payload.type)) {
      return TrackingMapView(orderId: payload.orderId);
    }

    if (payload.type == PushNotificationType.paymentConfirmed) {
      return const CustomerMainView(
        initialTab: CustomerMainViewTab.orders,
        initialOrdersTabIndex: 0,
      );
    }

    if (historyTabTypes.contains(payload.type)) {
      return const CustomerMainView(
        initialTab: CustomerMainViewTab.orders,
        initialOrdersTabIndex: 1,
      );
    }

    if (walletTypes.contains(payload.type)) {
      return const CustomerWalletView();
    }

    if (payload.orderId != null && payload.orderId!.isNotEmpty) {
      return const CustomerMainView(initialTab: CustomerMainViewTab.orders);
    }

    return null;
  }

  Widget? _driverScreenForPush({required PushNotificationPayload payload}) {
    const homeTypes = {
      PushNotificationType.deliveryAssigned,
      PushNotificationType.driverDeliveryAssigned,
      PushNotificationType.orderReady,
      PushNotificationType.driverOrderReady,
      PushNotificationType.driverPickupOtpValidated,
      PushNotificationType.orderDelivered,
    };

    if (homeTypes.contains(payload.type)) {
      return const DriverMainView(initialTab: DriverMainViewTab.home);
    }

    return null;
  }

  Widget? _managerScreenForPush({required PushNotificationPayload payload}) {
    const homeTypes = {
      PushNotificationType.paymentConfirmed,
      PushNotificationType.orderAccepted,
    };
    const preparationTabTypes = {PushNotificationType.orderPreparing};
    const readyTabTypes = {
      PushNotificationType.orderReady,
      PushNotificationType.deliveryAssigned,
    };
    const historyTabTypes = {
      PushNotificationType.orderRejected,
      PushNotificationType.orderDelivered,
    };

    if (homeTypes.contains(payload.type)) {
      return const ManagerMainView(initialTab: ManagerMainViewTab.home);
    }

    if (preparationTabTypes.contains(payload.type)) {
      return const ManagerMainView(
        initialTab: ManagerMainViewTab.orders,
        initialOrdersTabIndex: 0,
      );
    }

    if (readyTabTypes.contains(payload.type)) {
      return const ManagerMainView(
        initialTab: ManagerMainViewTab.orders,
        initialOrdersTabIndex: 1,
      );
    }

    if (historyTabTypes.contains(payload.type)) {
      return const ManagerMainView(
        initialTab: ManagerMainViewTab.orders,
        initialOrdersTabIndex: 2,
      );
    }

    return null;
  }
}
