import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:dineroo_mobile/shared/view_models/location/location_view_model.dart';
import 'package:flutter/material.dart';

Future<void> storeLocationIfGranted(BuildContext context) async {
  final permission = await Geolocator.checkPermission();
  if (context.mounted == false) return;

  final isGranted =
      permission == LocationPermission.always ||
      permission == LocationPermission.whileInUse;

  if (!isGranted) return;

  try {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    if (context.mounted) {
      context.read<LocationViewModel>().setPosition(
        LatLng(position.latitude, position.longitude),
      );
    }
  } catch (_) {}
}
