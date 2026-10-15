import 'package:flutter/material.dart';

enum OrderStatus {
  created,
  pendingPayment,
  paymentConfirmed,
  paymentFailed,
  accepted,
  rejected,
  preparing,
  readyForPickup,
  pickedUp,
  delivered,
  completed,
  canceled;

  static OrderStatus fromString(String value) {
    switch (value.trim().toUpperCase()) {
      case 'CREATED':
        return OrderStatus.created;
      case 'PENDING_PAYMENT':
        return OrderStatus.pendingPayment;
      case 'PAYMENT_CONFIRMED':
        return OrderStatus.paymentConfirmed;
      case 'PAYMENT_FAILED':
        return OrderStatus.paymentFailed;
      case 'ACCEPTED':
        return OrderStatus.accepted;
      case 'REJECTED':
        return OrderStatus.rejected;
      case 'PREPARING':
        return OrderStatus.preparing;
      case 'READY':
      case 'READY_FOR_PICKUP':
        return OrderStatus.readyForPickup;
      case 'PICKED_UP':
        return OrderStatus.pickedUp;
      case 'DELIVERED':
        return OrderStatus.delivered;
      case 'COMPLETED':
        return OrderStatus.completed;
      case 'CANCELED':
        return OrderStatus.canceled;
      default:
        throw FormatException('Unsupported order status from backend: $value');
    }
  }

  String get apiValue {
    switch (this) {
      case OrderStatus.created:
        return 'CREATED';
      case OrderStatus.pendingPayment:
        return 'PENDING_PAYMENT';
      case OrderStatus.paymentConfirmed:
        return 'PAYMENT_CONFIRMED';
      case OrderStatus.paymentFailed:
        return 'PAYMENT_FAILED';
      case OrderStatus.accepted:
        return 'ACCEPTED';
      case OrderStatus.rejected:
        return 'REJECTED';
      case OrderStatus.preparing:
        return 'PREPARING';
      case OrderStatus.readyForPickup:
        return 'READY_FOR_PICKUP';
      case OrderStatus.pickedUp:
        return 'PICKED_UP';
      case OrderStatus.delivered:
        return 'DELIVERED';
      case OrderStatus.completed:
        return 'COMPLETED';
      case OrderStatus.canceled:
        return 'CANCELED';
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.pendingPayment:
      case OrderStatus.created:
        return 'En attente de paiement';
      case OrderStatus.paymentConfirmed:
        return 'Paiement confirmé';
      case OrderStatus.paymentFailed:
        return 'Paiement échoué';
      case OrderStatus.accepted:
        return 'Acceptée';
      case OrderStatus.rejected:
        return 'Refusée';
      case OrderStatus.preparing:
        return 'En préparation';
      case OrderStatus.readyForPickup:
        return 'Prête à être récupérée';
      case OrderStatus.pickedUp:
        return 'Récupérée par le livreur';
      case OrderStatus.delivered:
        return 'Livrée';
      case OrderStatus.completed:
        return 'Terminée';
      case OrderStatus.canceled:
        return 'Annulée';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.created:
        return Colors.orangeAccent;
      case OrderStatus.pendingPayment:
        return Colors.deepOrange;
      case OrderStatus.paymentConfirmed:
        return Colors.amber;
      case OrderStatus.paymentFailed:
        return Colors.redAccent;
      case OrderStatus.accepted:
        return Colors.blue;
      case OrderStatus.rejected:
        return Colors.redAccent;
      case OrderStatus.preparing:
        return Colors.teal;
      case OrderStatus.readyForPickup:
        return Colors.purple;
      case OrderStatus.pickedUp:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.canceled:
        return Colors.red;
    }
  }

  Color get textColor => Colors.white;

  bool get isOngoing => [
    OrderStatus.created,
    OrderStatus.pendingPayment,
    OrderStatus.paymentConfirmed,
    OrderStatus.accepted,
    OrderStatus.preparing,
    OrderStatus.readyForPickup,
    OrderStatus.pickedUp,
  ].contains(this);

  bool get isHistory => hasReachedDeliveryStep || isFailure;

  bool get hasReachedDeliveryStep =>
      this == OrderStatus.pickedUp || isDeliveredOrCompleted;

  bool get isDeliveredOrCompleted =>
      this == OrderStatus.delivered || this == OrderStatus.completed;

  bool get isFailure => [
    OrderStatus.paymentFailed,
    OrderStatus.canceled,
    OrderStatus.rejected,
  ].contains(this);

  bool get hasReachedConfirmedStep =>
      [
        OrderStatus.accepted,
        OrderStatus.preparing,
        OrderStatus.readyForPickup,
        OrderStatus.pickedUp,
      ].contains(this) ||
      isDeliveredOrCompleted;
}
