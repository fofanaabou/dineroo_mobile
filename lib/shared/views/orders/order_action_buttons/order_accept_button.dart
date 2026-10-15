import 'package:dineroo_mobile/manager/view_models/home/manager_order_reception_view_model.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_button.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_snackbar.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OrderAcceptButton extends StatefulWidget {
  final String orderId;
  final bool isSmall;
  final bool enabled;
  final VoidCallback? onAccepted;
  final VoidCallback? onActionComplete;
  final double errorSnackbarBottomMargin;

  const OrderAcceptButton({
    super.key,
    required this.orderId,
    this.isSmall = false,
    this.enabled = true,
    this.onAccepted,
    this.onActionComplete,
    this.errorSnackbarBottomMargin = 16,
  });

  @override
  State<OrderAcceptButton> createState() => _OrderAcceptButtonState();
}

class _OrderAcceptButtonState extends State<OrderAcceptButton> {
  bool _isLoading = false;

  Future<void> _handleAccept() async {
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
    final success = await receptionVM.acceptOrder(restaurantId, widget.orderId);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!context.mounted) return;
    if (success) {
      AppSnackbar.success(context, 'Commande acceptée');
      widget.onAccepted?.call();
      widget.onActionComplete?.call();
    } else {
      AppSnackbar.error(
        context,
        'Impossible d\'accepter la commande.',
        bottomMargin: widget.errorSnackbarBottomMargin,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      text: 'ACCEPTER',
      isSmall: widget.isSmall,
      backgroundColor: Colors.green,
      isDisabled: _isLoading || !widget.enabled,
      isLoading: _isLoading,
      onPressed: widget.enabled && !_isLoading ? _handleAccept : null,
    );
  }
}
