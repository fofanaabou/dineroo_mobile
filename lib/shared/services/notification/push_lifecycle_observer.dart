import 'dart:async';

import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/services/notification/push_notification_service.dart';
import 'package:flutter/widgets.dart';

class PushLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state != AppLifecycleState.resumed) {
      return;
    }

    logger.i(
      '[Push] App resumed - checking whether silent device token sync is needed...',
    );
    unawaited(
      Future<void>(() async {
        try {
          await PushNotificationService()
              .silentlySyncPersistedUserDeviceTokenIfNeeded();
        } catch (e, stack) {
          logger.e(
            '[Push] Silent sync on app resume failed',
            error: e,
            stackTrace: stack,
          );
        }
      }),
    );
  }
}
