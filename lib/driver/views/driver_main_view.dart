import 'dart:async';
import 'package:provider/provider.dart';
import 'package:dineroo_mobile/driver/view_models/driver_home_view_model.dart';
import 'package:dineroo_mobile/driver/views/home/driver_home_view.dart';
import 'package:dineroo_mobile/driver/views/deliveries/driver_deliveries_history_view.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/enums/user_role.dart';
import 'package:dineroo_mobile/shared/realtime/stomp_realtime_service.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:dineroo_mobile/shared/gain/gain_view.dart';
import 'package:dineroo_mobile/shared/enums/main_view_tabs.dart';
import 'package:dineroo_mobile/shared/views/base_main_view.dart';
import 'package:dineroo_mobile/shared/views/profile/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class DriverMainView extends StatefulWidget {
  final DriverMainViewTab initialTab;

  const DriverMainView({super.key, this.initialTab = DriverMainViewTab.home});

  @override
  State<DriverMainView> createState() => _DriverMainViewState();

  static List<BottomNavigationBarItem> get bottomNavItems => const [
    BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Accueil'),
    BottomNavigationBarItem(
      icon: Icon(Icons.receipt_long_outlined),
      label: 'Historique',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.trending_up_outlined),
      label: 'Gains',
    ),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
  ];
}

class _DriverMainViewState extends State<DriverMainView> {
  static const Duration _driverLocationInterval = Duration(minutes: 1);
  static const double _minDistanceMetersToSend = 50;

  bool hideMenus = false;
  bool _sessionPrepared = false;
  Timer? _driverLocationTimer;
  Position? _lastSentPosition;
  bool _isRestoringSession = false;

  @override
  void initState() {
    super.initState();
    _startDriverLocationUpdates();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_sessionPrepared) {
      _sessionPrepared = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _restoreDriverSession();
      });
    }
  }

  @override
  void dispose() {
    _driverLocationTimer?.cancel();
    super.dispose();
  }

  Future<void> _restoreDriverSession() async {
    if (!mounted || _isRestoringSession) return;
    _isRestoringSession = true;
    try {
      await context
          .read<DriverHomeViewModel>()
          .restoreDriverSessionFromBackend();
    } finally {
      _isRestoringSession = false;
    }
  }

  void _startDriverLocationUpdates() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _sendDriverLocation();
      _driverLocationTimer = Timer.periodic(_driverLocationInterval, (_) {
        _sendDriverLocation();
      });
    });
  }

  Future<void> _sendDriverLocation() async {
    if (!mounted) return;

    final currentUser = context.read<CurrentUserViewModel>().currentUser;
    if (currentUser == null || currentUser.userRoleEnum != UserRole.driver) {
      return;
    }

    final permission = await Geolocator.checkPermission();
    final isGranted =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    if (!isGranted) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final lastPosition = _lastSentPosition;
      if (lastPosition != null) {
        final movedDistance = Geolocator.distanceBetween(
          lastPosition.latitude,
          lastPosition.longitude,
          position.latitude,
          position.longitude,
        );

        if (movedDistance < _minDistanceMetersToSend) {
          logger.i(
            '[DriverLocation] Skipped send: moved ${movedDistance.toStringAsFixed(1)}m (< ${_minDistanceMetersToSend.toStringAsFixed(0)}m)',
          );
          return;
        }
      }

      StompRealtimeService().sendDriverLocation(
        driverId: currentUser.id,
        longitude: position.longitude,
        latitude: position.latitude,
      );
      _lastSentPosition = position;
      logger.i(
        '[DriverLocation] Sent location lat=${position.latitude}, lng=${position.longitude}',
      );
    } catch (e, stack) {
      logger.e(
        '[DriverLocation] Failed to send location',
        error: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseMainView(
      initialIndex: widget.initialTab.index,
      navItems: DriverMainView.bottomNavItems,
      hideBottomNav: hideMenus,
      screenBuilder: (index) {
        switch (DriverMainViewTab.values[index]) {
          case DriverMainViewTab.home:
            return DriverHomeView(
              onHideMenusChanged: (hide) {
                setState(() {
                  hideMenus = hide;
                });
              },
            );
          case DriverMainViewTab.deliveriesHistory:
            return const DriverDeliveriesHistoryView();
          case DriverMainViewTab.earnings:
            return const GainView();
          case DriverMainViewTab.profile:
            return const ProfileView();
        }
      },
    );
  }
}
