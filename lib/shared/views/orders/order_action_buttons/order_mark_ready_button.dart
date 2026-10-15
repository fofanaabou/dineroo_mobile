import 'package:dineroo_mobile/manager/view_models/home/manager_order_reception_view_model.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_button.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_snackbar.dart';
import 'package:dineroo_mobile/shared/enums/order_status.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:dineroo_mobile/shared/views/orders/order_action_buttons/order_action_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OrderMarkReadyButton extends StatefulWidget {
  final String orderId;
  final bool isSmall;
  final bool enabled;
  final VoidCallback? onActionComplete;
  final double errorSnackbarBottomMargin;

  const OrderMarkReadyButton({
    super.key,
    required this.orderId,
    this.isSmall = false,
    this.enabled = true,
    this.onActionComplete,
    this.errorSnackbarBottomMargin = 16,
  });

  @override
  State<OrderMarkReadyButton> createState() => _OrderMarkReadyButtonState();
}

class _OrderMarkReadyButtonState extends State<OrderMarkReadyButton> {
  bool _isLoading = false;

  Future<void> _handleMarkReady() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final restaurantId = context
        .read<CurrentUserViewModel>()
        .currentUser
        ?.organization
        ?.id;

    if (restaurantId == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (!context.mounted) return;
      AppSnackbar.error(
        context,
        'Restaurant introuvable',
        bottomMargin: widget.errorSnackbarBottomMargin,
      );
      return;
    }

    final receptionVM = context.read<ManagerOrderReceptionViewModel>();
    final success = await receptionVM.updateStatus(
      restaurantId: restaurantId,
      orderId: widget.orderId,
      status: toRestaurantStatus(OrderStatus.readyForPickup),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!context.mounted) return;
    if (success) {
      applyLocalStatusUpdate(
        context,
        widget.orderId,
        OrderStatus.readyForPickup,
      );
      AppSnackbar.success(context, 'Commande marquée comme prête');
      widget.onActionComplete?.call();
      if (Navigator.of(context).canPop()) Navigator.pop(context);
    } else {
      AppSnackbar.error(
        context,
        'Échec lors de la mise à jour',
        bottomMargin: widget.errorSnackbarBottomMargin,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      text: 'Marquer prête',
      backgroundColor: Colors.green,
      isDisabled: _isLoading || !widget.enabled,
      isLoading: _isLoading,
      isSmall: widget.isSmall,
      onPressed: widget.enabled && !_isLoading ? _handleMarkReady : null,
    );
  }
}
