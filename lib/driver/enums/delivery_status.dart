enum DeliveryStatus {
  pending('PENDING'),
  assigned('ASSIGNED'),
  pickedUp('PICKED_UP'),
  delivered('DELIVERED'),
  canceled('CANCELED');

  final String apiValue;
  const DeliveryStatus(this.apiValue);

  static DeliveryStatus fromApi(String? value) {
    final normalized = value?.trim().toUpperCase();
    switch (normalized) {
      case 'ASSIGNED':
        return DeliveryStatus.assigned;
      case 'PICKED_UP':
        return DeliveryStatus.pickedUp;
      case 'DELIVERED':
        return DeliveryStatus.delivered;
      case 'CANCELED':
        return DeliveryStatus.canceled;
      case 'PENDING':
      default:
        return DeliveryStatus.pending;
    }
  }
}
