import 'package:dineroo_mobile/manager/views/manager_main_view.dart';
import 'package:dineroo_mobile/shared/common/colors.dart';
import 'package:dineroo_mobile/shared/common/helpers/navigation_helper.dart';
import 'package:dineroo_mobile/shared/view_models/auth/auth_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/user_role_view_model.dart';
import 'package:dineroo_mobile/shared/views/auth/whoiam_view.dart';
import 'package:dineroo_mobile/shared/views/location/location_access_view.dart';
import 'package:dineroo_mobile/customer/views/customer_main_view.dart';
import 'package:dineroo_mobile/driver/views/driver_main_view.dart';
import 'package:dineroo_mobile/shared/common/helpers/auth_helper.dart';
import 'package:dineroo_mobile/shared/view_models/app_update/app_update_view_model.dart';
import 'package:dineroo_mobile/shared/views/app_update/show_update_dialog.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

class InitialRedirectView extends StatefulWidget {
  const InitialRedirectView({super.key});

  @override
  State<InitialRedirectView> createState() => _InitialRedirectViewState();
}

class _InitialRedirectViewState extends State<InitialRedirectView> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final updateVM = context.read<AppUpdateViewModel>();
      await updateVM.check();
      if (!mounted) return;

      if (updateVM.shouldShowDialog && updateVM.result != null) {
        final result = updateVM.result!;
        await showAppUpdateDialog(
          context,
          result: result,
          onUpdate: updateVM.performUpdate,
        );
        if (!mounted) return;
        if (result.forceUpdate) return;
        updateVM.clear();
      }

      await _handleRedirect();
    });
  }

  Future<void> _handleRedirect() async {
    final authVM = context.read<AuthViewModel>();
    final currentUserVM = context.read<CurrentUserViewModel>();
    final roleVM = context.read<UserRoleViewModel>();

    final isLoggedIn = await authVM.isAuthenticated();
    if (!mounted) return;
    if (!isLoggedIn) {
      replaceWith(context, const WhoiamView());
      return;
    }

    await authVM.loadUserFromToken(context);
    if (!mounted) return;
    if (roleVM.isGuest) {
      final redirectedToUpload = await handleDriverAccountAccess(
        context,
        authVM,
        currentUserVM.currentUser,
      );
      if (redirectedToUpload) return;
      if (!mounted) return;
      replaceWith(context, const WhoiamView());
      return;
    }

    // Skip location permission for restaurant managers
    if (roleVM.isRestaurantManager) {
      replaceWith(context, const ManagerMainView());
      return;
    }

    final permission = await Geolocator.checkPermission();
    final isLocationGranted =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    if (!mounted) return;

    if (!isLocationGranted) {
      replaceWith(context, const LocationAccessView());
    } else if (roleVM.isDriver) {
      replaceWith(context, const DriverMainView());
    } else {
      replaceWith(context, const CustomerMainView());
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(backgroundColor: AppColors.orange);
  }
}
