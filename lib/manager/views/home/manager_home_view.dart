import 'dart:async';

import 'package:dineroo_mobile/manager/enums/order_source.dart';
import 'package:dineroo_mobile/manager/views/home/manager_home_empty_state.dart';
import 'package:dineroo_mobile/manager/views/home/manager_home_status_header.dart';
import 'package:dineroo_mobile/manager/views/home/manager_suspension_banner.dart';
import 'package:dineroo_mobile/manager/views/restaurant/opening_hours/restaurant_opening_hours_view.dart';
import 'package:dineroo_mobile/manager/view_models/restaurant/manager_restaurant_view_model.dart';
import 'package:dineroo_mobile/shared/common/helpers/navigation_helper.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:dineroo_mobile/shared/models/domain/order.dart';
import 'package:dineroo_mobile/manager/view_models/home/manager_order_reception_view_model.dart';
import 'package:dineroo_mobile/shared/services/notification/notification_sound_service.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_scaffold.dart';
import 'package:dineroo_mobile/manager/views/home/reception/manager_order_reception_card.dart';
import 'package:dineroo_mobile/shared/views/orders/order_detail_view.dart';
import 'package:dineroo_mobile/shared/realtime/stomp_realtime_service.dart';
import 'package:provider/provider.dart';

typedef ManagerHomeReconnect = Future<void> Function();
typedef ManagerHomeSoundAction = void Function();
typedef ManagerHomeOrderDetailBuilder = Widget Function(Order order);
typedef ManagerHomeOpenOrdersTab =
    void Function(BuildContext context, int tabIndex);

class ManagerHomeView extends StatefulWidget {
  final ManagerHomeReconnect? reconnectIfNeeded;
  final ManagerHomeSoundAction? playSoundLoop;
  final ManagerHomeSoundAction? stopSound;
  final ManagerHomeOrderDetailBuilder? orderDetailBuilder;
  final ManagerHomeOpenOrdersTab? onOpenOrdersTab;

  const ManagerHomeView({
    super.key,
    this.reconnectIfNeeded,
    this.playSoundLoop,
    this.stopSound,
    this.orderDetailBuilder,
    this.onOpenOrdersTab,
  });

  @override
  State<ManagerHomeView> createState() => _ManagerHomeViewState();
}

class _ManagerHomeViewState extends State<ManagerHomeView>
    with WidgetsBindingObserver {
  final _soundService = NotificationSoundService();
  final _realtimeService = StompRealtimeService();

  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeManagerHome();
    });
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _initializeManagerHome() async {
    final ctx = context;
    final receptionVM = ctx.read<ManagerOrderReceptionViewModel>();
    final restaurantVM = ctx.read<ManagerRestaurantViewModel>();

    await (widget.reconnectIfNeeded ?? _realtimeService.reconnectIfNeeded)();
    if (!ctx.mounted) return;
    await receptionVM.syncWithServer(ctx);
    await restaurantVM.loadRestaurantState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    switch (state) {
      case AppLifecycleState.resumed:
        _initializeManagerHome();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _stopSound();
        break;
      case AppLifecycleState.detached:
        _stopSound();
        break;
    }
  }

  void _playSoundLoop() => (widget.playSoundLoop ?? _soundService.playLoop)();
  void _stopSound() => (widget.stopSound ?? _soundService.stop)();

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final currentUser = context.watch<CurrentUserViewModel>().currentUser;
    final organizationName =
        currentUser?.organization?.name ?? 'Mon Restaurant';

    return AppScaffold(
      title: organizationName,
      showCartIcon: false,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: isLandscape ? _landscapeView(context) : _portraitView(context),
      ),
    );
  }

  Future<void> _onRefresh() async {
    final ctx = context;
    final receptionVM = ctx.read<ManagerOrderReceptionViewModel>();
    final restaurantVM = ctx.read<ManagerRestaurantViewModel>();

    if (!ctx.mounted) return;
    await receptionVM.syncWithServer(ctx);
    await restaurantVM.loadRestaurantState();
  }

  Future<void> _openOpeningHoursEditor() async {
    final restaurantVM = context.read<ManagerRestaurantViewModel>();
    final restaurantId = restaurantVM.currentRestaurantId;
    if (restaurantId == null || restaurantId.isEmpty) return;

    await navigateTo(
      context,
      RestaurantOpeningHoursView(restaurantId: restaurantId),
    );
    if (mounted) await restaurantVM.loadRestaurantState();
  }

  Widget _suspensionBannerAndStatusHeader(
    ManagerRestaurantViewModel restaurantVM,
  ) {
    final suspension = restaurantVM.suspension;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (suspension != null) ...[
          ManagerSuspensionBanner(suspension: suspension),
          const SizedBox(height: 12),
        ],
        ManagerHomeStatusHeader(
          openingHours: restaurantVM.openingHours,
          isLoading: restaurantVM.isLoading,
          isSuspended: restaurantVM.isSuspended,
          onTap: _openOpeningHoursEditor,
        ),
      ],
    );
  }

  Widget _portraitView(BuildContext context) {
    final vm = context.watch<ManagerOrderReceptionViewModel>();
    final restaurantVM = context.watch<ManagerRestaurantViewModel>();
    final orderCards = _dashboardOrderCards(vm, direction: Axis.horizontal);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompactHeight = constraints.maxHeight < 700;

        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _suspensionBannerAndStatusHeader(restaurantVM),
                    SizedBox(height: isCompactHeight ? 12 : 16),
                    orderCards,
                    SizedBox(height: isCompactHeight ? 12 : 18),
                    Expanded(child: _orderList(isHorizontal: false)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _landscapeView(BuildContext context) {
    final vm = context.watch<ManagerOrderReceptionViewModel>();
    final restaurantVM = context.watch<ManagerRestaurantViewModel>();
    final isCompactHeight = MediaQuery.sizeOf(context).height < 700;

    if (isCompactHeight) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: constraints.maxHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 260,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _suspensionBannerAndStatusHeader(restaurantVM),
                            const SizedBox(height: 12),
                            Expanded(
                              child: _dashboardOrderCards(
                                vm,
                                direction: Axis.vertical,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: _orderList(isHorizontal: true)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    _suspensionBannerAndStatusHeader(restaurantVM),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 260,
                            child: _dashboardOrderCards(
                              vm,
                              direction: Axis.vertical,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(child: _orderList(isHorizontal: true)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _dashboardOrderCards(
    ManagerOrderReceptionViewModel vm, {
    required Axis direction,
  }) {
    final cards = [
      _DashboardOrderCard(
        count: vm.newOrdersCount,
        label: 'Nouvelles commandes',
        icon: Icons.shopping_bag_outlined,
        color: const Color(0xFFFF4B12),
      ),
      _DashboardOrderCard(
        count: vm.readyOrdersCount,
        label: 'Commandes prêtes',
        icon: Icons.room_service_outlined,
        color: const Color(0xFF11A85A),
        onTap: () => widget.onOpenOrdersTab?.call(context, 1),
      ),
    ];

    if (direction == Axis.horizontal) {
      return Row(
        children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 12),
          Expanded(child: cards[1]),
        ],
      );
    }

    return Column(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(height: 14),
        Expanded(child: cards[1]),
      ],
    );
  }

  Widget _orderList({required bool isHorizontal}) {
    return Consumer<ManagerOrderReceptionViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading && vm.orders.isEmpty) {
          return const Center(child: AppLoader());
        }

        if (vm.orders.isEmpty) {
          _stopSound();
          return const ManagerHomeEmptyState();
        }

        final maxVisible = isHorizontal ? 6 : 4;
        final visibleOrders = vm.orders.take(maxVisible).toList();

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: List.generate(visibleOrders.length, (i) {
            final index = visibleOrders.length - 1 - i;
            final order = visibleOrders[index];
            final isTopCard = index == 0;

            final position = isHorizontal
                ? Positioned(
                    key: ValueKey('horizontal-${order.id}-$index'),
                    left: i * 60.0,
                    top: 0,
                    bottom: 0,
                    child: SizedBox(
                      width: 320,
                      child: _orderCard(order, isTopCard, vm),
                    ),
                  )
                : Positioned(
                    key: ValueKey('vertical-${order.id}-$index'),
                    bottom: i * 60.0,
                    left: 0,
                    right: 0,
                    child: _orderCard(order, isTopCard, vm),
                  );

            return position;
          }),
        );
      },
    );
  }

  Widget _orderCard(
    Order order,
    bool isTopCard,
    ManagerOrderReceptionViewModel vm,
  ) {
    return GestureDetector(
      onTap: isTopCard
          ? () async {
              final didUpdateOrder = await navigateTo<bool>(
                context,
                widget.orderDetailBuilder?.call(order) ??
                    OrderDetailView(
                      orderId: order.id.toString(),
                      source: OrderSource.reception,
                    ),
              );
              if (didUpdateOrder == true && mounted) {
                await _onRefresh();
              }
            }
          : null,
      child: ManagerOrderReceptionCard(
        order: order,
        enabled: isTopCard,
        onAnimationComplete: () {
          vm.removeOrder(order.id.toString());
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && vm.orders.isNotEmpty) {
              _playSoundLoop();
            }
          });
        },
        onMounted: isTopCard ? _playSoundLoop : null,
      ),
    );
  }
}

class _DashboardOrderCard extends StatelessWidget {
  final int count;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _DashboardOrderCard({
    required this.count,
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final countText = Text(
      '$count',
      style: TextStyle(
        color: color,
        fontSize: 34,
        height: 0.95,
        fontWeight: FontWeight.w800,
      ),
    );
    const labelStyle = TextStyle(
      color: Color(0xFF1C2331),
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.1,
    );
    final labelText = Text(
      label.toUpperCase(),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.visible,
      style: labelStyle,
    );
    final iconBadge = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 22),
    );

    return Material(
      color: const Color(0xFFFFFFFF),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 118),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFDDCC)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4B12).withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        iconBadge,
                        const SizedBox(width: 12),
                        countText,
                      ],
                    ),
                    const SizedBox(height: 8),
                    labelText,
                  ],
                ),
              ),
              if (onTap != null)
                Positioned(
                  right: 0,
                  child: Icon(Icons.chevron_right, color: color, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
