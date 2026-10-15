import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dineroo_mobile/shared/view_models/location/location_view_model.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';

class MapViewModel extends ChangeNotifier {
  LatLng? currentPosition;
  bool isLoading = false;
  String? error;

  Future<void> fetchCurrentLocation(BuildContext context) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final locationProvider = context.read<LocationViewModel>();

      if (locationProvider.userPosition != null) {
        currentPosition = locationProvider.userPosition;
      } else {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        currentPosition = LatLng(position.latitude, position.longitude);
      }
    } on LocationServiceDisabledException {
      error = 'Les services de localisation sont désactivés.';
      logger.e(error);
    } on PermissionDeniedException {
      error = 'Permission de localisation refusée.';
      logger.e(error);
    } catch (e) {
      error = 'Impossible d\'obtenir votre position.';
      logger.e('$error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
