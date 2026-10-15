import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapMarkers extends StatelessWidget {
  final LatLng? currentPosition;

  const MapMarkers({super.key, this.currentPosition});

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: [
        if (currentPosition != null)
          Marker(
            point: currentPosition!,
            width: 44,
            height: 44,
            child: const Icon(Icons.my_location, size: 28, color: Colors.black),
          ),
      ],
    );
  }
}
