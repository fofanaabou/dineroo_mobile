import 'package:dineroo_mobile/shared/common/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

TileLayer buildDefaultTileLayer(BuildContext context) {
  return TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    userAgentPackageName: Constants.userAgentPackageName,
    keepBuffer: 3,
    errorTileCallback: (tile, error, stackTrace) {
      final c = tile.coordinates;
      debugPrint('Map tile layer error: $error — z:${c.z} x:${c.x} y:${c.y}');
    },
  );
}
