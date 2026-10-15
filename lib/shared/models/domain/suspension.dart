import 'package:dineroo_mobile/shared/enums/suspension_reason.dart';

class Suspension {
  final SuspensionReason reason;
  final DateTime? suspendedAt;

  const Suspension({required this.reason, this.suspendedAt});

  factory Suspension.fromJson(Map<String, dynamic> json) {
    return Suspension(
      reason: SuspensionReason.fromApiValue(json['reason']?.toString()),
      suspendedAt: DateTime.tryParse(json['suspendedAt']?.toString() ?? ''),
    );
  }

  static Suspension? fromRestaurantJson(dynamic json) {
    if (json is! Map) return null;
    return Suspension.fromJson(Map<String, dynamic>.from(json));
  }

  @override
  String toString() =>
      'Suspension(reason: ${reason.apiValue}, suspendedAt: $suspendedAt)';
}
