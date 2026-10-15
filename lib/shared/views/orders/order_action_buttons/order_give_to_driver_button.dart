import 'package:dineroo_mobile/manager/view_models/home/manager_order_reception_view_model.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_button.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_dialog.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_snackbar.dart';
import 'package:dineroo_mobile/shared/enums/order_status.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:dineroo_mobile/shared/views/orders/order_action_buttons/order_action_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class OrderGiveToDriverButton extends StatefulWidget {
  final String orderId;
  final String shortId;
  final bool hasAssignedDriver;
  final bool isLoadingDriver;
  final bool isSmall;
  final bool enabled;
  final VoidCallback? onActionComplete;
  final double errorSnackbarBottomMargin;

  const OrderGiveToDriverButton({
    super.key,
    required this.orderId,
    required this.shortId,
    this.hasAssignedDriver = true,
    this.isLoadingDriver = false,
    this.isSmall = false,
    this.enabled = true,
    this.onActionComplete,
    this.errorSnackbarBottomMargin = 16,
  });

  @override
  State<OrderGiveToDriverButton> createState() =>
      _OrderGiveToDriverButtonState();
}

class _OrderGiveToDriverButtonState extends State<OrderGiveToDriverButton> {
  bool _isLoading = false;
  TextEditingController? _otpController;

  @override
  void dispose() {
    _otpController?.dispose();
    super.dispose();
  }

  void _openOtpDialog() {
    if (!widget.hasAssignedDriver) {
      AppSnackbar.warning(
        context,
        'Aucun livreur n\'est assigné à cette commande.',
        bottomMargin: widget.errorSnackbarBottomMargin,
      );
      return;
    }

    final parentContext = context;
    _otpController?.dispose();
    final controller = TextEditingController();
    _otpController = controller;
    String? errorText;

    showDialog(
      context: parentContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) {
          return AppDialog(
            title: 'Commande #${widget.shortId}',
            confirmText: 'Valider',
            isConfirmLoading: _isLoading,
            onCancel: _isLoading
                ? () {}
                : () => Navigator.of(dialogContext).pop(),
            onConfirm: _isLoading
                ? () {}
                : () async {
                    final code = controller.text.trim();
                    if (code.length != 4) {
                      setDialogState(
                        () => errorText = 'Le code doit contenir 4 chiffres.',
                      );
                      return;
                    }

                    setState(() => _isLoading = true);
                    setDialogState(() => errorText = null);

                    final currentUser = parentContext
                        .read<CurrentUserViewModel>()
                        .currentUser;

                    final receptionVM = parentContext
                        .read<ManagerOrderReceptionViewModel>();
                    String? message;
                    try {
                      message = await receptionVM.validatePickupOtp(
                        orderId: widget.orderId,
                        code: code,
                        validatedBy: currentUser?.id,
                        restaurantId: currentUser?.organization?.id ?? '',
                      );
                    } catch (_) {
                      if (!mounted) return;
                      setState(() => _isLoading = false);
                      setDialogState(
                        () => errorText =
                            'Erreur technique. Veuillez réessayer.',
                      );
                      return;
                    }

                    if (!mounted) return;
                    setState(() => _isLoading = false);

                    if (message == null) {
                      setDialogState(
                        () => errorText = 'Le code saisi est invalide.',
                      );
                      return;
                    }

                    if (!parentContext.mounted) return;
                    Navigator.of(dialogContext).pop();
                    applyLocalStatusUpdate(
                      parentContext,
                      widget.orderId,
                      OrderStatus.pickedUp,
                    );
                    AppSnackbar.success(
                      parentContext,
                      message.isNotEmpty
                          ? message
                          : 'Commande remise au livreur',
                    );
                    widget.onActionComplete?.call();
                  },
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saisissez le code à 4 chiffres communiqué par le livreur.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  enabled: !_isLoading,
                  onChanged: (_) {
                    if (errorText != null) {
                      setDialogState(() => errorText = null);
                    }
                  },
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: '0000',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 16,
                    ),
                    filled: true,
                    fillColor: _isLoading
                        ? const Color(0xFFEDEDED)
                        : const Color(0xFFF2F6FF),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    errorText!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      text: 'Remettre au livreur',
      backgroundColor: Colors.blue,
      isDisabled: _isLoading || widget.isLoadingDriver || !widget.enabled,
      isLoading: _isLoading,
      isSmall: widget.isSmall,
      onPressed: widget.enabled && !_isLoading ? _openOtpDialog : null,
    );
  }
}
