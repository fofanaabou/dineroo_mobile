import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/common/helpers/order_helper.dart';
import 'package:dineroo_mobile/shared/views/orders/order_card_container.dart';
import 'package:dineroo_mobile/driver/views/home/delivery_confirmation_view.dart';
import 'package:dineroo_mobile/shared/common/helpers/navigation_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_address_row.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_button.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_close_button.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_contact_card.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_dialog.dart';
import 'package:dineroo_mobile/shared/models/domain/contact.dart';

class DriverCardCustomer extends StatelessWidget {
  final String? customerName;
  final String? customerPhone;
  final String? endAddress;
  final String? orderId;
  final num? deliveryFee;
  final VoidCallback onPrimaryAction;
  final VoidCallback onClose;

  const DriverCardCustomer({
    super.key,
    this.customerName,
    this.customerPhone,
    this.endAddress,
    this.orderId,
    this.deliveryFee,
    required this.onPrimaryAction,
    required this.onClose,
  });

  String _extractDeliveryCode(String? phone) {
    final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return '';
    return digits.substring(digits.length - 4);
  }

  void _showConfirmationDialog(BuildContext context) {
    final expectedCode = _extractDeliveryCode(customerPhone);

    showDialog(
      context: context,
      builder: (_) => AppDialog(
        title: 'Confirmer la livraison !',
        message: 'Êtes-vous sûr de vouloir livrer la commande ?',
        confirmText: 'OUI',
        cancelText: 'NON',
        isShiftedUp: true,
        onConfirm: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
          replaceWith(
            context,
            DeliveryConfirmationView(
              deliveryFee: deliveryFee ?? 0,
              expectedCode: expectedCode,
              orderId: orderId,
            ),
          );
          onPrimaryAction();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasCustomerPhone = (customerPhone ?? '').trim().isNotEmpty;
    final hasCustomerName = (customerName ?? '').trim().isNotEmpty;
    final hasOrderId = (orderId ?? '').trim().isNotEmpty;

    return OrderCardContainer(
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(
                child: Text(
                  'Client',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A0338),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              if (hasOrderId)
                Center(
                  child: Text(
                    formatOrderReference(orderId),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              if (hasOrderId) const SizedBox(height: 12),

              if (hasCustomerName || hasCustomerPhone)
                AppContactCard(
                  contact: Contact(
                    name: hasCustomerName ? customerName! : 'Client',
                    phoneNumber: hasCustomerPhone ? customerPhone! : '',
                  ),
                ),

              const SizedBox(height: 8),
              if (endAddress != null && endAddress!.trim().isNotEmpty)
                AppAddressRow(address: endAddress!),
              const SizedBox(height: 24),
              AppButton(
                customChild: const Text(
                  "Je livre la commande",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                onPressed: () => _showConfirmationDialog(context),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AppCloseButton(
                  onPressed: () {
                    Navigator.of(context).maybePop();
                    onClose();
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
