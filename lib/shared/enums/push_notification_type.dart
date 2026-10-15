enum PushNotificationType {
  paymentConfirmed('payment_confirmed'),
  orderAccepted('order_accepted'),
  orderRejected('order_rejected'),
  orderPreparing('order_preparing'),
  orderReady('order_ready'),
  deliveryAssigned('delivery_assigned'),
  driverDeliveryAssigned('driver_delivery_assigned'),
  driverOrderReady('driver_order_ready'),
  driverPickupOtpValidated('driver_pickup_otp_validated'),
  orderDelivered('order_delivered'),
  walletRecredited('wallet_recredited'),
  walletCredited('wallet_credited'),
  walletDebited('wallet_debited'),
  courierDecision('courier_decision');

  final String wireValue;

  const PushNotificationType(this.wireValue);

  static PushNotificationType? fromWireValue(String? value) {
    for (final type in PushNotificationType.values) {
      if (type.wireValue == value) {
        return type;
      }
    }

    return null;
  }
}
