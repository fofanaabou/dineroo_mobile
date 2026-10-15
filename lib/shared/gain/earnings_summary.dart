import 'package:dineroo_mobile/shared/common/constants/currency_constants.dart';

class EarningsSummary {
  final num availableAmount;
  final num totalEarned;
  final num paidAmount;
  final int completedOrdersCount;
  final String currency;

  const EarningsSummary({
    required this.availableAmount,
    required this.totalEarned,
    this.paidAmount = 0,
    required this.completedOrdersCount,
    required this.currency,
  });

  factory EarningsSummary.empty() {
    return const EarningsSummary(
      availableAmount: 0,
      totalEarned: 0,
      paidAmount: 0,
      completedOrdersCount: 0,
      currency: appCurrency,
    );
  }

  EarningsSummary applyPaidAmount(num paidAmount) {
    final available = totalEarned - paidAmount;
    return EarningsSummary(
      availableAmount: available > 0 ? available : 0,
      totalEarned: totalEarned,
      paidAmount: paidAmount,
      completedOrdersCount: completedOrdersCount,
      currency: currency,
    );
  }

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    final totalEarned = _numValue(json['totalEarned']);
    return EarningsSummary(
      availableAmount: _numValue(json['availableAmount']),
      totalEarned: totalEarned,
      paidAmount: _numValue(json['paidAmount']),
      completedOrdersCount:
          (json['completedOrdersCount'] as num?)?.toInt() ?? 0,
      currency: json['currency']?.toString() ?? appCurrency,
    );
  }

  static num _numValue(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }
}
