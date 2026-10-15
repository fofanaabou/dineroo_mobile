enum PaymentStatus {
  pending('PENDING'),
  success('COMPLETED'),
  failed('FAILED'),
  canceled('CANCELED'),
  unknown('UNKNOWN');

  final String apiValue;
  const PaymentStatus(this.apiValue);

  static PaymentStatus fromApi(String? value) {
    final normalized = (value ?? '').trim().toUpperCase();
    return PaymentStatus.values.firstWhere(
      (status) => status.apiValue == normalized,
      orElse: () => PaymentStatus.unknown,
    );
  }
}
