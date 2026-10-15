class PayoutSummary {
  final num paidAmount;

  const PayoutSummary({required this.paidAmount});

  factory PayoutSummary.fromJson(Map<String, dynamic> json) {
    final value = json['paidAmount'];
    return PayoutSummary(
      paidAmount: value is num ? value : num.tryParse(value?.toString() ?? '') ?? 0,
    );
  }
}
