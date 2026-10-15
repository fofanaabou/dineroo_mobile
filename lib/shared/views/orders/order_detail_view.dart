import 'package:dineroo_mobile/customer/view_models/order/order_list_view_model.dart';
import 'package:dineroo_mobile/manager/enums/order_source.dart';
import 'package:dineroo_mobile/manager/views/home/details/manager_order_item_row.dart';
import 'package:dineroo_mobile/shared/views/orders/order_action_buttons/order_accept_button.dart';
import 'package:dineroo_mobile/shared/views/orders/order_action_buttons/order_give_to_driver_button.dart';
import 'package:dineroo_mobile/shared/views/orders/order_action_buttons/order_mark_ready_button.dart';
import 'package:dineroo_mobile/shared/views/orders/order_action_buttons/order_reject_button.dart';
import 'package:dineroo_mobile/shared/common/factories/contact_factory.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_context_helper.dart';
import 'package:dineroo_mobile/shared/common/helpers/order_helper.dart';
import 'package:dineroo_mobile/shared/common/helpers/price_helper.dart';
import 'package:dineroo_mobile/shared/common/utils/date_utils.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_contact_card.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_error_retry.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_scaffold.dart';
import 'package:dineroo_mobile/shared/enums/main_view_tabs.dart';
import 'package:dineroo_mobile/shared/enums/order_status.dart';
import 'package:dineroo_mobile/shared/models/domain/contact.dart';
import 'package:dineroo_mobile/shared/models/domain/order.dart';
import 'package:dineroo_mobile/shared/models/domain/order_details.dart';
import 'package:dineroo_mobile/shared/repositories/order_details_repository.dart';
import 'package:dineroo_mobile/shared/services/order/order_details_service.dart';
import 'package:dineroo_mobile/shared/services/order/shared_order_service.dart';
import 'package:dineroo_mobile/shared/view_models/order/order_detail_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:dineroo_mobile/shared/views/base_main_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OrderDetailView extends StatefulWidget {
  final dynamic orderId;
  final OrderSource? source;
  final OrderDetailViewModel? viewModel;

  const OrderDetailView({
    super.key,
    required this.orderId,
    this.source,
    this.viewModel,
  });

  bool get isManager => source != null;

  @override
  State<OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends State<OrderDetailView> {
  @override
  Widget build(BuildContext context) {
    if (widget.viewModel != null) {
      return ChangeNotifierProvider<OrderDetailViewModel>.value(
        value: widget.viewModel!,
        child: _buildConsumer(),
      );
    }

    return ChangeNotifierProvider(
      create: (ctx) {
        final vm = OrderDetailViewModel(
          sharedOrderService: SharedOrderService(),
          orderDetailsRepository: OrderDetailsRepository(
            service: OrderDetailsService(),
          ),
          apiContext: widget.isManager ? ApiContext.restaurant : null,
        );

        if (widget.isManager) {
          vm.init(widget.orderId);
        } else {
          final userVM = context.read<CurrentUserViewModel>();
          final orderListVM = context.read<OrderListViewModel>();
          final currentUser = userVM.currentUser;
          if (currentUser != null) {
            vm.initWithRealtime(
              widget.orderId,
              currentUser.id,
              onOrderFetched: (order) => orderListVM.upsertOrder(order),
              onRealtimeEvent: (event) =>
                  orderListVM.updateOrderStatusFromRealtime(event),
            );
          } else {
            vm.init(widget.orderId);
          }
        }

        return vm;
      },
      child: _buildConsumer(),
    );
  }

  Widget _buildConsumer() {
    return Consumer<OrderDetailViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return _buildScaffold(const Center(child: AppLoader()));
        }

        if (vm.error != null || vm.order == null) {
          return _buildScaffold(
            AppErrorRetry(onPressed: () => vm.fetchOrderById(widget.orderId)),
          );
        }

        return _buildBody(
          order: vm.order!,
          orderDetails: vm.orderDetails,
          vm: vm,
        );
      },
    );
  }

  Widget _buildScaffold(Widget body) {
    if (widget.isManager) {
      final selectedIndex = widget.source == OrderSource.reception
          ? ManagerMainViewTab.home.index
          : ManagerMainViewTab.orders.index;

      return BaseMainWrapper(
        role: UserRole.manager,
        selectedIndex: selectedIndex,
        child: AppScaffold(
          title: 'Détail de la commande',
          showBack: true,
          showCartIcon: false,
          body: body,
        ),
      );
    }

    return AppScaffold(
      title: 'Détail de la commande',
      showBack: true,
      showCartIcon: false,
      body: body,
    );
  }

  Color _statusColor(Order order) {
    if (widget.isManager && widget.source == OrderSource.reception) {
      return OrderStatus.created.color;
    }
    return order.status.color;
  }

  String _statusLabel(Order order) {
    if (widget.isManager && widget.source == OrderSource.reception) {
      return 'NOUVEAU';
    }
    return order.status.label;
  }

  Widget _buildBody({
    required Order order,
    required OrderDetails? orderDetails,
    required OrderDetailViewModel vm,
  }) {
    final driver = orderDetails?.driverDetails;
    final hasDriver = orderDetails?.hasAssignedDriver ?? false;

    final itemsSubtotal = order.items.fold<double>(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    final deliveryFee = order.deliveryFee ?? 0;
    final serviceFee = order.serviceFee ?? 0;
    final paidTotal = itemsSubtotal + deliveryFee + serviceFee;

    final bool hasOrderBeenAccepted = order.status.hasReachedConfirmedStep;

    final customerContact = ContactFactory.publicCustomer(
      deliveryContact: order.deliveryContact,
      subtitle: order.deliveryAddress,
    );

    final driverContact = driver != null
        ? ContactFactory.publicDriver(
            fullName: driver.fullName,
            phoneNumber: driver.phoneNumber,
          )
        : null;

    final bool showManagerDriverSection =
        hasOrderBeenAccepted &&
        (driverContact != null || widget.source != OrderSource.history);

    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusBanner(
          order: order,
          statusColor: _statusColor(order),
          statusLabel: _statusLabel(order),
          showRestaurantName: !widget.isManager,
        ),
        const SizedBox(height: 20),
        _ItemsSection(order: order),
        const SizedBox(height: 20),
        if (widget.isManager)
          _ManagerTotalSection(totalPrice: order.totalPrice)
        else
          _FinancialSection(
            itemsSubtotal: itemsSubtotal,
            deliveryFee: deliveryFee,
            serviceFee: serviceFee,
            paidTotal: paidTotal,
          ),
        if (order.hasComment) ...[
          const SizedBox(height: 20),
          _CommentSection(comment: order.comment!),
        ],
        if (!widget.isManager) ...[
          const SizedBox(height: 20),
          _DeliveryInfoSection(address: order.deliveryAddress),
        ],
        if (widget.isManager && hasOrderBeenAccepted) ...[
          const SizedBox(height: 20),
          _ClientSection(contact: customerContact),
        ],
        if (widget.isManager && showManagerDriverSection) ...[
          const SizedBox(height: 20),
          _ManagerDriverSection(driverContact: driverContact),
        ],
        if (!widget.isManager && hasDriver) ...[
          const SizedBox(height: 20),
          _CustomerDriverSection(driver: driver!),
        ],
        const SizedBox(height: 4),
      ],
    );

    if (widget.isManager && widget.source != OrderSource.history) {
      return _buildScaffold(
        Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await vm.fetchOrderById(widget.orderId);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: content,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEAEAEA))),
              ),
              child: SafeArea(top: false, child: _buildActionButtons(order, orderDetails, isLoading: vm.isLoading)),
            ),
          ],
        ),
      );
    }

    return _buildScaffold(
      RefreshIndicator(
        onRefresh: () async {
          await vm.fetchOrderById(widget.orderId);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: content,
        ),
      ),
    );
  }

  Widget _buildActionButtons(Order order, OrderDetails? orderDetails, {bool isLoading = false}) {
    const detailErrorSnackbarBottomMargin = 80.0;

    switch (widget.source) {
      case OrderSource.reception:
        return Row(
          children: [
            Expanded(
              child: OrderRejectButton(
                orderId: order.id.toString(),
                errorSnackbarBottomMargin: detailErrorSnackbarBottomMargin,
                onActionComplete: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop(true);
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OrderAcceptButton(
                orderId: order.id.toString(),
                errorSnackbarBottomMargin: detailErrorSnackbarBottomMargin,
                onActionComplete: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop(true);
                  }
                },
              ),
            ),
          ],
        );
      case OrderSource.ready:
        return OrderGiveToDriverButton(
          orderId: order.id.toString(),
          shortId: order.shortId,
          hasAssignedDriver: orderDetails?.hasAssignedDriver ?? false,
          isLoadingDriver: isLoading,
          errorSnackbarBottomMargin: detailErrorSnackbarBottomMargin,
          onActionComplete: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop(true);
            }
          },
        );
      case OrderSource.ongoing:
        return OrderMarkReadyButton(
          orderId: order.id.toString(),
          errorSnackbarBottomMargin: detailErrorSnackbarBottomMargin,
          onActionComplete: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop(true);
            }
          },
        );
      case OrderSource.history:
        return const SizedBox.shrink();
      case null:
        return const SizedBox.shrink();
    }
  }
}

class _StatusBanner extends StatelessWidget {
  final Order order;
  final Color statusColor;
  final String statusLabel;
  final bool showRestaurantName;

  const _StatusBanner({
    required this.order,
    required this.statusColor,
    required this.statusLabel,
    required this.showRestaurantName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            formatOrderReference(order.id),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Créée le ${formatDateTime(order.createdDate)}',
            style: const TextStyle(fontSize: 13, color: Colors.black45),
          ),
          if (order.statusDate != null) ...[
            const SizedBox(height: 2),
            Text(
              '${order.status.label} le ${formatDateTime(order.statusDate!)}',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
          if (showRestaurantName && order.restaurantName.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              order.restaurantName,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemsSection extends StatelessWidget {
  final Order order;

  const _ItemsSection({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Contenu de la commande'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEAEAEA)),
          ),
          child: Column(
            children: [
              ...order.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == order.items.length - 1 ? 0 : 10,
                  ),
                  child: ManagerOrderItemRow(item: item),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _ManagerTotalSection extends StatelessWidget {
  final double totalPrice;

  const _ManagerTotalSection({required this.totalPrice});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Prix total',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Text(
            formatPrice(totalPrice),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _FinancialSection extends StatelessWidget {
  final double itemsSubtotal;
  final double deliveryFee;
  final double serviceFee;
  final double paidTotal;

  const _FinancialSection({
    required this.itemsSubtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.paidTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEAEAEA)),
          ),
          child: Column(
            children: [
              _FinancialRow(
                label: 'Sous-total produits',
                value: formatPrice(itemsSubtotal),
              ),
              if (deliveryFee > 0) ...[
                const SizedBox(height: 8),
                _FinancialRow(
                  label: 'Frais de livraison',
                  value: formatPrice(deliveryFee),
                ),
              ],
              if (serviceFee > 0) ...[
                const SizedBox(height: 8),
                _FinancialRow(
                  label: 'Frais de service',
                  value: formatPrice(serviceFee),
                ),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: Color(0xFFD0D0D0)),
              ),
              _FinancialRow(
                label: 'Total payé',
                value: formatPrice(paidTotal),
                isTotal: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FinancialRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _FinancialRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _CommentSection extends StatelessWidget {
  final String comment;

  const _CommentSection({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Commentaire'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            comment,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _DeliveryInfoSection extends StatelessWidget {
  final String address;

  const _DeliveryInfoSection({required this.address});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Informations de livraison'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEAEAEA)),
          ),
          child: Text(
            address,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _ClientSection extends StatelessWidget {
  final Contact contact;

  const _ClientSection({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Client'),
        const SizedBox(height: 4),
        AppContactCard(contact: contact, showCallButton: false),
      ],
    );
  }
}

class _ManagerDriverSection extends StatelessWidget {
  final Contact? driverContact;

  const _ManagerDriverSection({required this.driverContact});

  @override
  Widget build(BuildContext context) {
    final contact = driverContact;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Livreur assigné'),
        const SizedBox(height: 4),
        if (contact != null)
          AppContactCard(contact: contact)
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Aucun livreur assigné pour le moment',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ),
      ],
    );
  }
}

class _CustomerDriverSection extends StatelessWidget {
  final DriverDetails driver;

  const _CustomerDriverSection({required this.driver});

  @override
  Widget build(BuildContext context) {
    final driverContact = ContactFactory.publicDriver(
      fullName: driver.fullName,
      phoneNumber: driver.phoneNumber,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Livreur assigné'),
        const SizedBox(height: 4),
        AppContactCard(contact: driverContact),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
    );
  }
}
