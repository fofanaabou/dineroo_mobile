import 'package:dineroo_mobile/shared/common/constants/constants.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_contact_support_button.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:dineroo_mobile/shared/views/map/map_layers.dart';
import 'package:dineroo_mobile/shared/views/map/map_markers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:dineroo_mobile/shared/view_models/map/map_view_model.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_error_retry.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  bool _hasRequestedLocation = false;
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MapViewModel(),
      child: Consumer<MapViewModel>(
        builder: (context, vm, _) {
          if (!_hasRequestedLocation) {
            _hasRequestedLocation = true;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await vm.fetchCurrentLocation(context);
            });
          }

          if (vm.error != null) {
            return Scaffold(
              backgroundColor: Colors.white,
              body: AppErrorRetry(
                onPressed: () => vm.fetchCurrentLocation(context),
                message: vm.error ?? 'Impossible de récupérer votre position.',
                icon: const Icon(
                  Icons.location_off,
                  size: 48,
                  color: Colors.red,
                ),
              ),
            );
          }

          if (vm.isLoading || vm.currentPosition == null) {
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(child: AppLoader()),
            );
          }

          return Scaffold(
            backgroundColor: Colors.white,
            body: Stack(
              children: [
                SizedBox.expand(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: vm.currentPosition!,
                      initialZoom: 15,
                    ),
                    children: [
                      buildDefaultTileLayer(context),
                      MapMarkers(currentPosition: vm.currentPosition),
                    ],
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).size.height / 6 - 30,
                  right: 16,
                  child: const AppContactSupportButton(
                    phoneNumber: Constants.supportPhoneNumber,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
