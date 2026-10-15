import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/models/domain/order_event.dart';
import 'package:dineroo_mobile/shared/services/notification/notification_sound_service.dart';
import 'package:dineroo_mobile/main.dart';
import 'package:provider/provider.dart';
import 'package:dineroo_mobile/manager/view_models/home/manager_order_reception_view_model.dart';

class RestaurantEventHandler {
  void handle(OrderEvent event) {
    logger.i(
      '[RT] Nouvelle commande reçue: ${event.orderId} (${event.status})',
    );

    final context = navigatorKey.currentContext;
    if (context == null) {
      logger.w('[RT] RestaurantEventHandler ignored: no navigator context');
      return;
    }

    NotificationSoundService().playLoop();

    context.read<ManagerOrderReceptionViewModel>().handleRealtimeOrder(
      event,
      context,
    );
  }
}
