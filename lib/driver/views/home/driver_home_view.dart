import 'package:dineroo_mobile/driver/enums/driver_ui_transition.dart';
import 'package:dineroo_mobile/driver/view_models/driver_home_view_model.dart';
import 'package:dineroo_mobile/driver/views/home/card/driver_card_customer.dart';
import 'package:dineroo_mobile/driver/views/home/card/driver_card_reception.dart';
import 'package:dineroo_mobile/driver/views/home/card/driver_card_restaurant.dart';
import 'package:dineroo_mobile/driver/views/home/go_external_map_button.dart';
import 'package:dineroo_mobile/driver/views/home/go_offline_button.dart';
import 'package:dineroo_mobile/driver/views/home/go_online_button.dart';
import 'package:dineroo_mobile/driver/views/home/searching_rides_button.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_button.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_snackbar.dart';
import 'package:dineroo_mobile/shared/common/utils/wakelock_utils.dart';
import 'package:dineroo_mobile/shared/views/map/map_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

typedef DriverHomeWakelockAction =
    Future<void> Function(bool shouldKeepScreenOn);
typedef DriverHomeWakelockDisable = Future<void> Function();
typedef DriverHomeMapBuilder = Widget Function(BuildContext context);

class DriverHomeView extends StatefulWidget {
  final void Function(bool hideMenus)? onHideMenusChanged;
  final DriverHomeWakelockAction? wakelockSync;
  final DriverHomeWakelockDisable? wakelockDisable;
  final DriverHomeMapBuilder? mapViewBuilder;

  const DriverHomeView({
    super.key,
    this.onHideMenusChanged,
    this.wakelockSync,
    this.wakelockDisable,
    this.mapViewBuilder,
  });

  @override
  State<DriverHomeView> createState() => _DriverHomeViewState();
}

class _DriverHomeViewState extends State<DriverHomeView>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimationController _controller;

  DriverHomeViewModel? _viewModel;
  bool _isDialogOpen = false;
  String? _lastErrorShown;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final driverHomeVM = context.read<DriverHomeViewModel>();
    if (_viewModel != driverHomeVM) {
      _viewModel?.removeListener(_handleViewModelUpdates);
      _viewModel = driverHomeVM;
      _viewModel!.addListener(_handleViewModelUpdates);
      (widget.wakelockSync ?? WakeLockUtils.sync)(_viewModel!.isOnline);
    }
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_handleViewModelUpdates);
    (widget.wakelockDisable ?? WakeLockUtils.disable)();
    _controller.dispose();
    super.dispose();
  }

  void _handleViewModelUpdates() {
    if (!mounted || _viewModel == null) return;

    (widget.wakelockSync ?? WakeLockUtils.sync)(_viewModel!.isOnline);

    final error = _viewModel!.error;
    if (error != null && error.isNotEmpty && error != _lastErrorShown) {
      _lastErrorShown = error;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AppSnackbar.error(context, error, bottomMargin: 80);
      });
    } else if (error == null || error.isEmpty) {
      _lastErrorShown = null;
    }

    final command = _viewModel!.consumePendingUiTransition();
    if (command == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      switch (command) {
        case DriverUiTransition.showIncomingRideDialog:
          if (!_isDialogOpen) {
            _showReceptionDialog();
          } else {
            logger.i(
              '[DriverHomeView] Incoming dialog transition skipped: dialog already open',
            );
          }
          break;
        case DriverUiTransition.showRestaurantDialog:
          if (!_isDialogOpen) {
            _showRestaurantDialog();
          } else {
            logger.i(
              '[DriverHomeView] Restaurant dialog transition skipped: dialog already open',
            );
          }
          break;
        case DriverUiTransition.showCustomerDialog:
          if (!_isDialogOpen) {
            _showCustomerDialog();
          } else {
            logger.i(
              '[DriverHomeView] Customer dialog transition skipped: dialog already open',
            );
          }
          break;
        case DriverUiTransition.hideDialogs:
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).maybePop();
          }
          _isDialogOpen = false;
          widget.onHideMenusChanged?.call(false);
          break;
      }
    });
  }

  Future<void> _goOnline() async {
    final driverHomeVM = context.read<DriverHomeViewModel>();
    if (driverHomeVM.isOnline || driverHomeVM.isLoading) return;

    try {
      await driverHomeVM.goOnline();
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error(
        context,
        driverHomeVM.error ?? "Impossible de passer en ligne.",
        bottomMargin: 80,
      );
    }
  }

  Future<void> _goOffline() async {
    final driverHomeVM = context.read<DriverHomeViewModel>();
    if (driverHomeVM.isLoading) return;

    try {
      await driverHomeVM.goOffline();
      widget.onHideMenusChanged?.call(false);
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error(
        context,
        driverHomeVM.error ?? "Impossible de passer hors ligne.",
        bottomMargin: 80,
      );
    }
  }

  void _showReceptionDialog() {
    final delivery = context.read<DriverHomeViewModel>().currentDelivery;
    if (delivery == null) return;

    _isDialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => DriverCardReception(
        price: delivery.deliveryFee,
        restaurantDistanceLabel:
            '${delivery.restaurantName} à ${delivery.estimatedDeliveryDistance.toStringAsFixed(1)} km',
        startAddress: delivery.pickupAddress,
        endAddress: delivery.deliveryAddress,
        onAccept: () async {
          final driverHomeVM = context.read<DriverHomeViewModel>();
          try {
            await driverHomeVM.acceptIncomingRide();
            widget.onHideMenusChanged?.call(true);
          } catch (_) {
            if (!mounted) return;
            AppSnackbar.error(
              context,
              driverHomeVM.error ?? "Impossible d'accepter la course",
            );
          }
        },
        onClose: () {
          _isDialogOpen = false;
        },
      ),
    ).then((_) {
      _isDialogOpen = false;
      logger.i('[DriverHomeView] Reception dialog closed');
      if (!mounted) return;
      context.read<DriverHomeViewModel>().clearIncomingIfNotAccepted();
    });
  }

  void _showRestaurantDialog() {
    final vm = context.read<DriverHomeViewModel>();
    if (vm.currentDelivery == null) return;

    _isDialogOpen = true;
    widget.onHideMenusChanged?.call(true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => DriverCardRestaurant(
        estimatedTime: vm.estimatedDeliveryDistanceLabel,
        startAddress: vm.pickupAddress,
        restaurantName: vm.restaurantName,
        restaurantPhone: vm.restaurantPhone,
        orderId: vm.currentOrderId,
        pickupOtpCode: vm.pickupOtpCode,
        onPrimaryAction: () {
          return context.read<DriverHomeViewModel>().moveToCustomerStep();
        },
        onClose: () {
          _isDialogOpen = false;
        },
      ),
    ).then((_) {
      _isDialogOpen = false;
    });
  }

  void _showCustomerDialog() {
    final vm = context.read<DriverHomeViewModel>();
    if (vm.currentDelivery == null) return;

    _isDialogOpen = true;
    widget.onHideMenusChanged?.call(true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => DriverCardCustomer(
        deliveryFee: vm.deliveryFee,
        customerName: vm.customerName,
        customerPhone: vm.customerPhone,
        endAddress: vm.deliveryAddress,
        orderId: vm.currentOrderId,
        onPrimaryAction: () {},
        onClose: () {
          _isDialogOpen = false;
        },
      ),
    ).then((_) {
      _isDialogOpen = false;
    });
  }

  void _handleDisplayTrip(DriverHomeViewModel driverHomeVM) {
    if (driverHomeVM.isHeadingToCustomer) {
      _showCustomerDialog();
      return;
    }

    if (driverHomeVM.isHeadingToRestaurant) {
      _showRestaurantDialog();
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final driverHomeVM = context.watch<DriverHomeViewModel>();
    final mapDestination = driverHomeVM.currentMapDestination;
    final isTripButtonLoading =
        driverHomeVM.isLoadingOrderDetails ||
        (driverHomeVM.isHeadingToCustomer && driverHomeVM.isLoading);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            (widget.mapViewBuilder ?? (_) => const MapView())(context),

            if (!driverHomeVM.isOnline)
              Align(
                alignment: Alignment.bottomCenter,
                child: GoOnlineButton(
                  isLoading: driverHomeVM.isLoading,
                  onPressed: driverHomeVM.isLoading ? null : _goOnline,
                ),
              ),

            if (driverHomeVM.isOnline && !driverHomeVM.isOnRide)
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: GoOfflineButton(
                    isLoading: driverHomeVM.isLoading,
                    onPressed: driverHomeVM.isLoading ? null : _goOffline,
                  ),
                ),
              ),

            if (driverHomeVM.isOnline && !driverHomeVM.isOnRide)
              Align(
                alignment: Alignment.bottomCenter,
                child: SearchingRidesButton(controller: _controller),
              ),

            if (driverHomeVM.canStartRide)
              Positioned(
                bottom: 96,
                left: 0,
                right: 0,
                child: GoExternalMapButton(
                  label: mapDestination.label,
                  query: mapDestination.query,
                  latitude: mapDestination.latitude,
                  longitude: mapDestination.longitude,
                ),
              ),

            if (driverHomeVM.canStartRide)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AppButton(
                    backgroundColor: Colors.black,
                    isLoading: isTripButtonLoading,
                    onPressed: isTripButtonLoading
                        ? null
                        : () => _handleDisplayTrip(driverHomeVM),
                    customChild: Text(
                      driverHomeVM.isHeadingToCustomer
                          ? 'Afficher la livraison'
                          : 'Afficher la course',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
