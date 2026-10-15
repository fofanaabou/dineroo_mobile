import 'package:dineroo_mobile/manager/view_models/home/manager_order_reception_view_model.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_button.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_dialog.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_snackbar.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OrderRejectButton extends StatefulWidget {
  final String orderId;
  final bool isSmall;
  final bool enabled;
  final VoidCallback? onRejected;
  final VoidCallback? onActionComplete;
  final double errorSnackbarBottomMargin;

  const OrderRejectButton({
    super.key,
    required this.orderId,
    this.isSmall = false,
    this.enabled = true,
    this.onRejected,
    this.onActionComplete,
    this.errorSnackbarBottomMargin = 16,
  });

  @override
  State<OrderRejectButton> createState() => _OrderRejectButtonState();
}

class _OrderRejectButtonState extends State<OrderRejectButton> {
  bool _isLoading = false;

  void _confirmReject() {
    final restaurantId = context
        .read<CurrentUserViewModel>()
        .currentUser
        ?.organization
        ?.id;

    showDialog(
      context: context,
      builder: (_) => AppDialog(
        title: 'Refuser la commande',
        message: 'Êtes-vous sûr de vouloir refuser cette commande ?',
        confirmText: 'Oui, refuser',
        cancelText: 'Annuler',
        onConfirm: () async {
          Navigator.of(context).pop();
          setState(() => _isLoading = true);

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
          final success = await receptionVM.rejectOrder(
            restaurantId,
            widget.orderId,
          );

          if (!mounted) return;
          setState(() => _isLoading = false);

          if (!context.mounted) return;
          if (success) {
            AppSnackbar.warning(context, 'Commande refusée');
            widget.onRejected?.call();
            widget.onActionComplete?.call();
          } else {
            AppSnackbar.error(
              context,
              'Erreur lors du refus de la commande',
              bottomMargin: widget.errorSnackbarBottomMargin,
            );
          }
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      text: 'REFUSER',
      backgroundColor: Colors.red,
      isSmall: widget.isSmall,
      isDisabled: _isLoading || !widget.enabled,
      isLoading: _isLoading,
      onPressed: widget.enabled && !_isLoading ? _confirmReject : null,
    );
  }
}
