import 'package:dineroo_mobile/manager/view_models/restaurant/manager_restaurant_view_model.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_snackbar.dart';
import 'package:dineroo_mobile/shared/exceptions/restaurant_suspended_exception.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ManagerSuspensionNotice {
  const ManagerSuspensionNotice._();

  static const String title = 'Restaurant suspendu';
  static const String supportPrompt =
      'Contactez le support Dineroo pour plus d\'informations.';
  static const String lockedActionReason =
      'Action indisponible : votre restaurant est suspendu.';

  static void showLockedAction(
    BuildContext context, {
    double bottomMargin = 16,
  }) {
    AppSnackbar.warning(context, lockedActionReason, bottomMargin: bottomMargin);
  }

  static Future<void> showServerRefusalAndReloadRestaurant(
    BuildContext context, {
    required String restaurantId,
    double bottomMargin = 16,
  }) async {
    final restaurantVM = context.read<ManagerRestaurantViewModel>();
    AppSnackbar.warning(
      context,
      RestaurantSuspendedException.message,
      bottomMargin: bottomMargin,
    );
    await restaurantVM.loadRestaurantState(restaurantId);
  }
}
