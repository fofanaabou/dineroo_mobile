import 'package:dineroo_mobile/shared/common/constants/hive_type_ids.dart';
import 'package:hive/hive.dart';

part 'delivery_address.g.dart';

@HiveType(typeId: HiveTypeIds.deliveryAddress)
class DeliveryAddress extends HiveObject {
  @HiveField(0)
  final String phoneNumber;

  @HiveField(1)
  final String address;

  @HiveField(2)
  final String district;

  @HiveField(3)
  final String? commune;

  @HiveField(4)
  final String? instructions;

  @HiveField(5)
  final String? firstName;

  @HiveField(6)
  final String? lastName;

  DeliveryAddress({
    required this.phoneNumber,
    required this.address,
    required this.district,
    this.commune,
    this.instructions,
    this.firstName,
    this.lastName,
  });

  String get displayLabel {
    final parts =
        <String>[
          address.trim(),
          district.trim(),
          if ((commune ?? '').trim().isNotEmpty) commune!.trim(),
        ].where((e) => e.isNotEmpty).toList();

    return parts.join(', ');
  }

  String get fullName {
    final parts =
        [
          firstName?.trim(),
          lastName?.trim(),
        ].where((e) => e != null && e.isNotEmpty).cast<String>().toList();

    return parts.join(' ');
  }

  String get displayName {
    final value = fullName.trim();
    return value.isNotEmpty ? value : 'Client';
  }

  DeliveryAddress copyWith({
    String? phoneNumber,
    String? address,
    String? district,
    String? commune,
    String? instructions,
    String? firstName,
    String? lastName,
  }) {
    return DeliveryAddress(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      district: district ?? this.district,
      commune: commune ?? this.commune,
      instructions: instructions ?? this.instructions,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
    );
  }
}
