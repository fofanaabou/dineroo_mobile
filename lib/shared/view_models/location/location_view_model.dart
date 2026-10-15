import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class LocationViewModel extends ChangeNotifier {
  LatLng? userPosition;

  void setPosition(LatLng position) {
    userPosition = position;
    notifyListeners();
  }
}
