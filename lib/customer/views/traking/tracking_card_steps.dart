import 'package:dineroo_mobile/shared/enums/order_status.dart';
import 'package:dineroo_mobile/customer/views/traking/tracking_card_steps_step.dart';
import 'package:dineroo_mobile/shared/models/domain/contact.dart';
import 'package:flutter/material.dart';

class TrackingCardSteps extends StatelessWidget {
  final Contact? driverContact;
  final OrderStatus status;

  const TrackingCardSteps({
    super.key,
    required this.status,
    this.driverContact,
  });

  String get _orderPlacedSubtitle {
    switch (status) {
      case OrderStatus.pendingPayment:
        return 'Paiement en attente de confirmation';
      default:
        return 'Votre commande a bien été enregistrée';
    }
  }

  String get _orderConfirmedSubtitle {
    switch (status) {
      case OrderStatus.paymentConfirmed:
      case OrderStatus.accepted:
        return 'Le restaurant a accepté votre commande';
      case OrderStatus.preparing:
        return 'Le restaurant prépare votre commande';
      case OrderStatus.readyForPickup:
        return 'La commande est prête à être récupérée';
      default:
        return 'Le restaurant a finalisé votre commande';
    }
  }

  String get _deliverySubtitle {
    switch (status) {
      case OrderStatus.preparing:
        return 'Un livreur a été assigné à votre commande';
      case OrderStatus.readyForPickup:
        return 'Un livreur va récupérer votre commande';
      case OrderStatus.pickedUp:
        return 'Le livreur a récupéré votre commande';
      case OrderStatus.delivered:
        return 'Votre commande a été livrée';
      case OrderStatus.completed:
        return 'Votre commande a bien été livrée';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (status.isFailure) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2F0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFF7643)),
            ),
            child: Text(
              status == OrderStatus.rejected
                  ? 'Commande refusée'
                  : status == OrderStatus.canceled
                  ? 'Commande annulée'
                  : status == OrderStatus.paymentFailed
                  ? 'Paiement échoué'
                  : 'Commande arrêtée',
              style: const TextStyle(
                color: Color(0xFFFF7643),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TrackingCardStepsStep(
          icon: Icons.check,
          backgroundColor: Colors.black,
          iconColor: Colors.white,
          title: 'Commande passée',
          subtitle: _orderPlacedSubtitle,
          isDisabled: false,
        ),
        TrackingCardStepsStep(
          icon: Icons.check,
          backgroundColor: const Color(0xFF2C1A4B),
          iconColor: Colors.white,
          title: 'Commande confirmée',
          subtitle: _orderConfirmedSubtitle,
          isDisabled: !status.hasReachedConfirmedStep,
        ),
        TrackingCardStepsStep(
          icon: Icons.delivery_dining,
          backgroundColor: const Color(0xFF2C1A4B),
          iconColor: Colors.white,
          title: 'En cours de livraison',
          subtitle: _deliverySubtitle,
          connectorHeight: 120,
          contact: driverContact,
          isDisabled: !status.hasReachedDeliveryStep,
        ),
        TrackingCardStepsStep(
          icon: Icons.home_filled,
          backgroundColor: Colors.green,
          iconColor: Colors.white,
          title: 'Livrée',
          subtitle: 'Votre commande a été livrée',
          isDisabled: !status.isDeliveredOrCompleted,
        ),
        TrackingCardStepsStep(
          icon: Icons.check_circle,
          backgroundColor: Colors.green,
          iconColor: Colors.white,
          title: 'Commande terminée',
          subtitle: 'Merci pour votre commande !',
          showConnector: false,
          isDisabled: status != OrderStatus.completed,
        ),
      ],
    );
  }
}
