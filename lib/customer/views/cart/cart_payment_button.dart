import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:dineroo_mobile/customer/exceptions/order_creation_exception.dart';
import 'package:dineroo_mobile/customer/enums/checkout_payment_method.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dineroo_mobile/customer/models/domain/cart_group.dart';
import 'package:dineroo_mobile/customer/view_models/cart/cart_view_model.dart';
import 'package:dineroo_mobile/customer/view_models/order/order_view_model.dart';
import 'package:dineroo_mobile/customer/view_models/payment/payment_view_model.dart';
import 'package:dineroo_mobile/customer/view_models/restaurant/restaurant_view_model.dart';
import 'package:dineroo_mobile/customer/views/cart/delivery_contact_form_sheet.dart';
import 'package:dineroo_mobile/customer/views/customer_main_view.dart';
import 'package:dineroo_mobile/customer/views/orders/order_placed_view.dart';
import 'package:dineroo_mobile/customer/views/payment/payment_view.dart';
import 'package:dineroo_mobile/customer/views/payment/payment_method_choice_sheet.dart';
import 'package:dineroo_mobile/shared/common/helpers/navigation_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_button.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_snackbar.dart';
import 'package:dineroo_mobile/customer/enums/payment_gateway_result.dart';
import 'package:dineroo_mobile/customer/enums/payment_status.dart';
import 'package:dineroo_mobile/shared/models/dto/order_request_dto.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/models/domain/order.dart';
import 'package:dineroo_mobile/customer/models/domain/payment.dart';
import 'package:dineroo_mobile/customer/view_models/wallet/wallet_view_model.dart';

class CartPaymentButton extends StatefulWidget {
  final CartGroup group;

  final String text;
  final double? width;
  final Future<bool?> Function(
    BuildContext context,
    String title,
    String submitLabel,
  )?
  openDeliveryForm;
  final Future<bool> Function(BuildContext context, String restaurantId)?
  restaurantOpenChecker;
  final Future<Order> Function(
    BuildContext context,
    CartGroup group,
    CartViewModel cartVM,
    dynamic currentUser,
  )?
  createOrder;
  final Future<Payment> Function(
    BuildContext context,
    CartGroup group,
    PaymentViewModel paymentVM,
    dynamic currentUser,
    Order createdOrder,
  )?
  createPayment;
  final Future<PaymentGatewayResult?> Function(
    BuildContext context,
    Payment payment,
  )?
  openPaymentGateway;
  final Future<PaymentStatus> Function(
    BuildContext context,
    PaymentViewModel paymentVM,
    String paymentId,
  )?
  waitForPaymentStatus;
  final Future<PaymentStatus?> Function(
    PaymentViewModel paymentVM,
    String paymentId,
  )?
  refreshPaymentStatus;
  final void Function(
    BuildContext context,
    CartGroup group,
    CartViewModel cartVM,
    Order createdOrder,
  )?
  onPaymentConfirmed;
  final void Function(BuildContext context)? returnToListing;

  const CartPaymentButton({
    super.key,
    required this.group,
    this.text = 'Payer',
    this.width,
    this.openDeliveryForm,
    this.restaurantOpenChecker,
    this.createOrder,
    this.createPayment,
    this.openPaymentGateway,
    this.waitForPaymentStatus,
    this.refreshPaymentStatus,
    this.onPaymentConfirmed,
    this.returnToListing,
  });

  @override
  State<CartPaymentButton> createState() => _CartPaymentButtonState();
}

class _CartPaymentButtonState extends State<CartPaymentButton> {
  bool _isSubmitting = false;

  static const String _gatewayUrlTemplate = '{token}';

  Future<PaymentStatus> _waitForBackendConfirmation({
    required BuildContext context,
    required PaymentViewModel paymentVM,
    required String paymentId,
    Duration timeout = const Duration(seconds: 30),
    Duration interval = const Duration(seconds: 2),
  }) async {
    PaymentStatus last = PaymentStatus.unknown;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              AppLoader(size: 20, strokeWidth: 2),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Confirmation du paiement…',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final start = DateTime.now();
    bool isWithinTimeout() => DateTime.now().difference(start) < timeout;

    try {
      while (isWithinTimeout()) {
        final refreshed = await paymentVM.refresh(paymentId);
        last = refreshed?.status ?? PaymentStatus.unknown;
        if (last == PaymentStatus.success ||
            last == PaymentStatus.failed ||
            last == PaymentStatus.canceled) {
          break;
        }
        await Future.delayed(interval);
      }
    } finally {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    }
    return last;
  }

  Future<PaymentStatus?> _refreshOnce({
    required PaymentViewModel paymentVM,
    required String paymentId,
  }) async {
    try {
      final refreshed = await paymentVM.refresh(paymentId);
      return refreshed?.status;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _validateRestaurantOpen() async {
    final bool isOpen;
    try {
      isOpen = widget.restaurantOpenChecker == null
          ? await _defaultRestaurantOpenChecker(
              context,
              widget.group.restaurantId,
            )
          : await widget.restaurantOpenChecker!(
              context,
              widget.group.restaurantId,
            );
    } catch (e, stack) {
      logger.e(
        '[PAYMENT][CHECKOUT] restaurant open check failed',
        error: e,
        stackTrace: stack,
      );
      if (!mounted) return false;
      AppSnackbar.error(
        context,
        'Impossible de vérifier les horaires du restaurant. Veuillez réessayer.',
        bottomMargin: 80,
      );
      return false;
    }

    if (!mounted) return false;
    if (!isOpen) {
      AppSnackbar.error(
        context,
        'Ce restaurant est actuellement fermé.',
        bottomMargin: 80,
      );
      return false;
    }
    return true;
  }

  void _showUnavailableItems(List<String> itemNames) {
    final displayedNames = itemNames.take(3).join(', ');
    final suffix = itemNames.length > 3 ? '…' : '';
    AppSnackbar.error(
      context,
      'Indisponible pour le moment : $displayedNames$suffix',
      bottomMargin: 80,
    );
  }

  void _handleRestaurantUnavailable(CartViewModel cartVM) {
    cartVM.removeCartGroup(widget.group.restaurantId);
    AppSnackbar.error(
      context,
      'Ce restaurant n\'est plus disponible.',
      bottomMargin: 80,
    );
    final returnToListing = widget.returnToListing;
    if (returnToListing != null) {
      returnToListing(context);
      return;
    }
    replaceAll(context, const CustomerMainView());
  }

  void _showValidationErrors(List<String> errors) {
    final displayed = errors.take(3).join(', ');
    final suffix = errors.length > 3 ? '…' : '';
    AppSnackbar.error(
      context,
      'Sélection invalide : $displayed$suffix',
      bottomMargin: 80,
    );
  }

  dynamic _validateCurrentUser() {
    final currentUser = context.read<CurrentUserViewModel>().currentUser;
    if (currentUser == null) {
      AppSnackbar.error(context, 'Utilisateur non connecté.', bottomMargin: 80);
      return null;
    }
    return currentUser;
  }

  bool _validateDeliveryInfo(CartViewModel cartVM) {
    final missingFields = <String>[];

    if ((cartVM.deliveryFirstName ?? '').trim().isEmpty) {
      missingFields.add('le prénom');
    }
    if ((cartVM.deliveryPhoneNumber ?? '').trim().isEmpty) {
      missingFields.add('le téléphone');
    }
    if ((cartVM.deliveryAddress ?? '').trim().isEmpty) {
      missingFields.add('l’adresse');
    }
    if ((cartVM.deliveryDistrict ?? '').trim().isEmpty) {
      missingFields.add('le quartier');
    }
    if (missingFields.isNotEmpty) {
      final message = missingFields.length == 1
          ? 'Veuillez renseigner ${missingFields.first}.'
          : 'Veuillez renseigner ${_joinFieldsForMessage(missingFields)}.';

      AppSnackbar.error(context, message, bottomMargin: 80);
      return false;
    }
    return true;
  }

  String _joinFieldsForMessage(List<String> fields) {
    if (fields.length == 1) return fields.first;
    if (fields.length == 2) return '${fields[0]} et ${fields[1]}';

    final allButLast = fields.sublist(0, fields.length - 1).join(', ');
    final last = fields.last;
    return '$allButLast et $last';
  }

  Future<Order> _createOrder({
    required CartViewModel cartVM,
    required dynamic currentUser,
  }) async {
    if (widget.createOrder != null) {
      return widget.createOrder!(context, widget.group, cartVM, currentUser);
    }

    final orderVM = context.read<OrderViewModel>();
    final dto = OrderRequestDto.fromCart(
      cart: widget.group,
      currentUser: currentUser,
      cartVM: cartVM,
      comment: cartVM.commentController.text.trim(),
    );
    return orderVM.createOrder(dto.toJson());
  }

  Future<Payment> _createPayment({
    required PaymentViewModel paymentVM,
    required dynamic currentUser,
    required Order createdOrder,
    required CheckoutPaymentMethod paymentMethod,
    required double walletBalance,
  }) {
    if (widget.createPayment != null) {
      return widget.createPayment!(
        context,
        widget.group,
        paymentVM,
        currentUser,
        createdOrder,
      );
    }

    final estimatedTotal = context.read<CartViewModel>().totalFor(widget.group);
    if (estimatedTotal == null) {
      throw Exception('Order estimation is unavailable');
    }
    final walletAmount = paymentMethod == CheckoutPaymentMethod.wallet
        ? walletBalance.clamp(0, estimatedTotal).toDouble()
        : 0.0;
    return paymentVM.createPayment(
      customerId: currentUser.id,
      orderId: createdOrder.id,
      amount: estimatedTotal,
      paymentMethod: paymentMethod == CheckoutPaymentMethod.wallet
          ? 'WALLET'
          : null,
      walletAmount: walletAmount,
    );
  }

  Future<PaymentGatewayResult?> _openPaymentGateway(Payment payment) {
    if (widget.openPaymentGateway != null) {
      return widget.openPaymentGateway!(context, payment);
    }

    return Navigator.of(context).push<PaymentGatewayResult>(
      MaterialPageRoute(
        builder: (_) => PaymentView(
          paymentId: payment.id,
          paymentToken: payment.paymentToken,
          paymentGatewayUrlTemplate: _gatewayUrlTemplate,
        ),
      ),
    );
  }

  void _onPaymentConfirmed({
    required CartViewModel cartVM,
    required Order createdOrder,
  }) {
    if (widget.onPaymentConfirmed != null) {
      widget.onPaymentConfirmed!(context, widget.group, cartVM, createdOrder);
      return;
    }

    cartVM.removeCartGroup(widget.group.restaurantId);
    cartVM.clearDeliveryAddress();
    AppSnackbar.success(context, 'Paiement confirmé avec succès');
    replaceLastScreens(context, OrderPlacedView(order: createdOrder), 2);
  }

  Future<void> _handleGatewayResult({
    required PaymentGatewayResult gatewayResult,
    required PaymentViewModel paymentVM,
    required CartViewModel cartVM,
    required Payment payment,
    required Order createdOrder,
  }) async {
    switch (gatewayResult) {
      case PaymentGatewayResult.success:
        final status = widget.waitForPaymentStatus == null
            ? await _waitForBackendConfirmation(
                context: context,
                paymentVM: paymentVM,
                paymentId: payment.id,
              )
            : await widget.waitForPaymentStatus!(
                context,
                paymentVM,
                payment.id,
              );
        if (!mounted) return;

        if (status == PaymentStatus.success) {
          _onPaymentConfirmed(cartVM: cartVM, createdOrder: createdOrder);
          return;
        }
        if (status == PaymentStatus.failed ||
            status == PaymentStatus.canceled) {
          AppSnackbar.error(
            context,
            'Paiement refusé. Veuillez réessayer.',
            bottomMargin: 80,
          );
          return;
        }
        AppSnackbar.warning(
          context,
          'Paiement validé côté opérateur, confirmation en cours…',
          bottomMargin: 80,
        );
        return;

      case PaymentGatewayResult.failed:
        AppSnackbar.error(
          context,
          'Paiement refusé. Veuillez réessayer.',
          bottomMargin: 80,
        );
        return;

      case PaymentGatewayResult.noStatus:
      case PaymentGatewayResult.canceled:
        // User closed / No signal (do one refresh to avoid false negatives)
        final refreshedStatus = widget.refreshPaymentStatus == null
            ? await _refreshOnce(paymentVM: paymentVM, paymentId: payment.id)
            : await widget.refreshPaymentStatus!(paymentVM, payment.id);
        if (!mounted) return;

        if (refreshedStatus == PaymentStatus.success) {
          _onPaymentConfirmed(cartVM: cartVM, createdOrder: createdOrder);
          return;
        }
        if (refreshedStatus == PaymentStatus.failed ||
            refreshedStatus == PaymentStatus.canceled) {
          AppSnackbar.error(
            context,
            'Paiement refusé. Veuillez réessayer.',
            bottomMargin: 80,
          );
          return;
        }
        AppSnackbar.warning(
          context,
          'Paiement interrompu. Veuillez réessayer.',
          bottomMargin: 80,
        );
        return;
    }
  }

  Future<void> _onPayPressed() async {
    if (_isSubmitting) return;

    try {
      if (widget.group.items.isEmpty) return;

      final paymentVM = context.read<PaymentViewModel>();
      final cartVM = context.read<CartViewModel>();

      if (!cartVM.isDeliveryConfirmedForCurrentOrder) {
        final addressSaved = widget.openDeliveryForm == null
            ? await DeliveryContactFormSheet.open(
                context,
                title: 'Confirmer la livraison',
                submitLabel: 'Continuer vers le paiement',
              )
            : await widget.openDeliveryForm!(
                context,
                'Confirmer la livraison',
                'Continuer vers le paiement',
              );
        if (!mounted || addressSaved != true) return;
      }

      setState(() => _isSubmitting = true);

      final restaurantOk = await _validateRestaurantOpen();
      if (!restaurantOk) return;

      final currentUser = _validateCurrentUser();
      if (currentUser == null) return;

      final estimatedTotal = cartVM.totalFor(widget.group);
      if (estimatedTotal == null) {
        throw Exception('Order estimation is unavailable');
      }

      final deliveryOk = _validateDeliveryInfo(cartVM);
      if (!deliveryOk) return;

      cartVM.clearUnavailableItemsForRestaurant(widget.group.restaurantId);

      final createdOrder = await _createOrder(
        cartVM: cartVM,
        currentUser: currentUser,
      );

      if (!mounted) return;
      final walletVM = context.read<WalletViewModel>();
      final wallet = await walletVM.getWallet(
        currentUser.id,
      );
      if (!mounted) return;

      final selectedPaymentMethod = await PaymentMethodChoiceSheet.open(
        context: context,
        orderTotal: estimatedTotal,
        walletBalance: wallet.balance,
        currency: wallet.currency,
      );
      if (!mounted || selectedPaymentMethod == null) return;

      final payment = await _createPayment(
        paymentVM: paymentVM,
        currentUser: currentUser,
        createdOrder: createdOrder,
        paymentMethod: selectedPaymentMethod,
        walletBalance: wallet.balance,
      );

      cartVM.consumeDeliveryConfirmation();

      if (selectedPaymentMethod == CheckoutPaymentMethod.wallet &&
          wallet.balance >= estimatedTotal) {
        if (payment.status == PaymentStatus.success) {
          _onPaymentConfirmed(cartVM: cartVM, createdOrder: createdOrder);
          return;
        }
        if (!mounted) return;
        AppSnackbar.error(
          context,
          'Paiement Wallet refusé. Veuillez réessayer.',
          bottomMargin: 80,
        );
        return;
      }

      final gatewayResult = await _openPaymentGateway(payment);
      if (!mounted) return;
      if (gatewayResult == null) {
        AppSnackbar.warning(
          context,
          'Paiement interrompu. Veuillez réessayer.',
          bottomMargin: 80,
        );
        return;
      }

      await _handleGatewayResult(
        gatewayResult: gatewayResult,
        paymentVM: paymentVM,
        cartVM: cartVM,
        payment: payment,
        createdOrder: createdOrder,
      );
    } on OrderCreationException catch (e, stack) {
      logger.e(
        '[PAYMENT][CHECKOUT] order creation error',
        error: e,
        stackTrace: stack,
      );
      if (!mounted) return;
      if (e.isRestaurantUnavailable) {
        _handleRestaurantUnavailable(context.read<CartViewModel>());
        return;
      }
      if (e.unavailableItems.isNotEmpty) {
        context.read<CartViewModel>().markUnavailableItems(
          widget.group.restaurantId,
          e.unavailableItems,
        );
        _showUnavailableItems(e.unavailableItems);
        return;
      }
      if (e.validationErrors.isNotEmpty) {
        _showValidationErrors(e.validationErrors);
        return;
      }
      AppSnackbar.error(
        context,
        'Impossible de créer la commande. Veuillez réessayer.',
        bottomMargin: 80,
      );
    } catch (e, stack) {
      logger.e('[PAYMENT][CHECKOUT] error', error: e, stackTrace: stack);
      if (!mounted) return;
      AppSnackbar.error(
        context,
        'Une erreur est survenue. Veuillez réessayer.',
        bottomMargin: 80,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<bool> _defaultRestaurantOpenChecker(
    BuildContext context,
    String restaurantId,
  ) {
    return context.read<RestaurantViewModel>().restaurantIsOpen(restaurantId);
  }

  @override
  Widget build(BuildContext context) {
    final cartVM = context.watch<CartViewModel>();
    final hasEstimation = cartVM.hasEstimationFor(widget.group.restaurantId);
    final isEstimating = cartVM.isEstimating(widget.group.restaurantId);
    final isDisabled =
        widget.group.items.isEmpty || !hasEstimation || isEstimating;

    final button = AppButton(
      text: widget.text,
      isDisabled: isDisabled,
      isLoading: _isSubmitting,
      onPressed: isDisabled ? null : _onPayPressed,
    );

    if (widget.width == null) return button;
    return SizedBox(width: widget.width, child: button);
  }
}
