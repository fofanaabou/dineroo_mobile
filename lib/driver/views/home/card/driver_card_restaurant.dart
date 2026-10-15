import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/common/helpers/order_helper.dart';
import 'package:dineroo_mobile/shared/views/orders/order_card_container.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_address_row.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_button.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_call_button.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_close_button.dart';

class DriverCardRestaurant extends StatefulWidget {
  final String? estimatedTime;
  final String? startAddress;
  final String? restaurantName;
  final String? restaurantPhone;
  final String? orderId;
  final String? pickupOtpCode;
  final Future<String?> Function() onPrimaryAction;
  final VoidCallback onClose;

  const DriverCardRestaurant({
    super.key,
    this.estimatedTime,
    this.startAddress,
    this.restaurantName,
    this.restaurantPhone,
    this.orderId,
    this.pickupOtpCode,
    required this.onPrimaryAction,
    required this.onClose,
  });

  @override
  State<DriverCardRestaurant> createState() => _DriverCardRestaurantState();
}

class _DriverCardRestaurantState extends State<DriverCardRestaurant> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _pickupAction() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final errorMessage = await widget.onPrimaryAction();
      if (!mounted) return;
      if (errorMessage == null) {
        Navigator.of(context).pop();
      } else {
        setState(() {
          _errorMessage = errorMessage;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Une erreur est survenue. Veuillez réessayer.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRestaurantPhone = (widget.restaurantPhone ?? '').trim().isNotEmpty;
    final otp = (widget.pickupOtpCode ?? '').trim();

    return OrderCardContainer(
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(
                child: Text(
                  'Restaurant',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A0338),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              if ((widget.orderId ?? '').trim().isNotEmpty)
                Center(
                  child: Text(
                    formatOrderReference(widget.orderId),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: 380,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.restaurantName ?? 'Restaurant',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF32343E),
                          ),
                        ),
                      ),
                      if (hasRestaurantPhone) ...[
                        const SizedBox(width: 12),
                        AppCallButton(phoneNumber: widget.restaurantPhone!),
                      ],
                    ],
                  ),
                ),
              ),
              if (widget.estimatedTime != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 6),
                  child: Text(
                    widget.estimatedTime!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF32343E),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              if (widget.startAddress != null && widget.startAddress!.trim().isNotEmpty)
                AppAddressRow(address: widget.startAddress!),
              if (otp.isNotEmpty) ...[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F6FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Code à donner au restaurant',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        otp,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 8,
                          color: Color(0xFF0A0338),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F0),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFCCCC)),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFCC0000),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              AppButton(
                customChild: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "J'ai récupéré la commande",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                onPressed: _isLoading ? null : () => _pickupAction(),
              ),
            ],
          ),
          if (!_isLoading)
            Positioned(
              top: 0,
              right: 0,
              child: AppCloseButton(
                onPressed: () {
                  Navigator.of(context).maybePop();
                  widget.onClose();
                },
              ),
            ),
        ],
      ),
    );
  }
}
