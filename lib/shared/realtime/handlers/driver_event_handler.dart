import 'package:provider/provider.dart';
import 'package:dineroo_mobile/main.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/driver/models/domain/driver_delivery_event.dart';
import 'package:dineroo_mobile/driver/view_models/driver_home_view_model.dart';

class DriverEventHandler {
  void handle(DriverDeliveryEvent event) {
    logger.i('[RT][DRIVER] Raw delivery event received: ${event.toJson()}');

    final context = navigatorKey.currentContext;
    if (context == null) {
      logger.w('[RT] DriverEventHandler ignored: no navigator context');
      return;
    }

    context.read<DriverHomeViewModel>().handleRealtimeDelivery(event);
  }
}
