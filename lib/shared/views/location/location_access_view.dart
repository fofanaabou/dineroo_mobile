import 'package:dineroo_mobile/customer/views/customer_main_view.dart';
import 'package:dineroo_mobile/shared/common/helpers/auth_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_snackbar.dart';
import 'package:dineroo_mobile/driver/views/driver_main_view.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_button.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_dialog.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:dineroo_mobile/shared/view_models/auth/auth_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/location/location_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/user_role_view_model.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../common/helpers/navigation_helper.dart';

class LocationAccessView extends StatefulWidget {
  const LocationAccessView({super.key});

  @override
  State<LocationAccessView> createState() => _LocationAccessViewState();
}

class _LocationAccessViewState extends State<LocationAccessView> {
  bool _isLoading = false;

  Future<void> _handleLocationPermission() async {
    setState(() => _isLoading = true);

    final authVM = context.read<AuthViewModel>();
    final currentUserVM = context.read<CurrentUserViewModel>();
    final roleVM = context.read<UserRoleViewModel>();

    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;

    if (!serviceEnabled) {
      AppSnackbar.error(
        context,
        'Les services de localisation sont désactivés.',
      );
      setState(() => _isLoading = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (!mounted) return;

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (!mounted) return;

      if (permission == LocationPermission.denied) {
        AppSnackbar.error(context, 'Permission de localisation refusée.');
        setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => AppDialog(
              title: 'Autorisation requise',
              message:
                  'Vous avez refusé l\'accès à votre position de manière permanente.\n\n'
                  'Pour continuer, veuillez autoriser l\'accès à la localisation dans les paramètres de votre appareil.',
              confirmText: 'Aller aux paramètres',
              onConfirm: () {
                Geolocator.openAppSettings();
                Navigator.pop(context);
              },
              onCancel: () => Navigator.pop(context),
            ),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!mounted) return;

      final provider = context.read<LocationViewModel>();
      provider.setPosition(LatLng(position.latitude, position.longitude));

      if (roleVM.isGuest) {
        await handleDriverAccountAccess(
          context,
          authVM,
          currentUserVM.currentUser,
        );
        return;
      } else if (roleVM.isDriver) {
        replaceAll(context, const DriverMainView());
      } else {
        replaceAll(context, const CustomerMainView());
      }
    } catch (e) {
      AppSnackbar.error(context, 'Impossible d\'obtenir la position.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 56,
                          child: Center(child: AppLoader()),
                        )
                        : AppButton(
                          text: 'AUTORISER LA LOCALISATION',
                          onPressed: _handleLocationPermission,
                          icon: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.location_on,
                              color: Colors.white,
                            ),
                          ),
                        ),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'DINEROO n’accède à votre position que pour vous proposer les restaurants proches.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF646982),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
