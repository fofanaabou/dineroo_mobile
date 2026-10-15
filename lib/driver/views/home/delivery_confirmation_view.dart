import 'package:dineroo_mobile/driver/views/driver_success_ride_view.dart';
import 'package:dineroo_mobile/shared/common/helpers/order_helper.dart';
import 'package:dineroo_mobile/shared/common/helpers/navigation_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_bottom_sheet.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_button.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_scaffold.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_verify_code_input.dart';
import 'package:flutter/material.dart';

class DeliveryConfirmationView extends StatefulWidget {
  final num deliveryFee;
  final String expectedCode;
  final String? orderId;

  const DeliveryConfirmationView({
    super.key,
    required this.deliveryFee,
    required this.expectedCode,
    this.orderId,
  });

  @override
  State<DeliveryConfirmationView> createState() =>
      _DeliveryConfirmationViewState();
}

class _DeliveryConfirmationViewState extends State<DeliveryConfirmationView> {
  String _enteredCode = '';
  String? _errorMessage;
  bool _isCodeValid = false;
  bool _isLoading = false;

  Future<void> _verifyCode(String code) async {
    final normalizedCode = code.trim();

    if (normalizedCode.length != 4) {
      setState(() {
        _errorMessage = 'Veuillez saisir les 4 chiffres du code.';
        _isCodeValid = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (!mounted) return;

    if (widget.expectedCode.isEmpty) {
      setState(() {
        _errorMessage = 'Code client indisponible. Veuillez réessayer.';
        _isCodeValid = false;
        _isLoading = false;
      });
      return;
    }

    if (normalizedCode == widget.expectedCode) {
      setState(() {
        _isCodeValid = true;
        _isLoading = false;
      });

      replaceAll(
        context,
        DriverSuccessRideView(deliveryFee: widget.deliveryFee),
      );
    } else {
      setState(() {
        _errorMessage = 'Code incorrect. Veuillez réessayer.';
        _isCodeValid = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AppScaffold(
        title: '',
        showBack: false,
        showCartIcon: false,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Confirmation de livraison',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if ((widget.orderId ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            formatOrderReference(widget.orderId),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0A0338),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 24),
                        const Text(
                          'Veuillez saisir le code à 4 chiffres du client',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        AppVerifyCodeInput(
                          errorMessage: _errorMessage,
                          onEditing: (isEditing) {
                            if (!isEditing) return;
                            setState(() {
                              _enteredCode = '';
                              _errorMessage = null;
                            });
                          },
                          onCompleted: (code) {
                            setState(() => _enteredCode = code);
                            _verifyCode(code);
                          },
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          text: 'VALIDER',
                          onPressed:
                              (_isLoading ||
                                      _isCodeValid ||
                                      _enteredCode.trim().length != 4)
                                  ? null
                                  : () => _verifyCode(_enteredCode),
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              builder:
                                  (_) => const AppBottomSheet(
                                    icon: Icons.info_outline,
                                    title: 'Astuce',
                                    message:
                                        'Le code de livraison correspond aux 4 derniers chiffres du numéro de téléphone du client.',
                                  ),
                            );
                          },
                          child: const Text(
                            "Le client ne trouve pas le code",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
