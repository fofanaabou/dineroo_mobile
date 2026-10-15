class OrderDeliveryContact {
  final String phoneNumber;
  final String address;
  final String? district;
  final String? commune;
  final String? instructions;
  final String? firstName;
  final String? lastName;

  const OrderDeliveryContact({
    required this.phoneNumber,
    required this.address,
    this.district,
    this.commune,
    this.instructions,
    this.firstName,
    this.lastName,
  });

  String get fullAddress {
    final parts =
        [
          address.trim(),
          district?.trim(),
          commune?.trim(),
        ].where((e) => e != null && e.isNotEmpty).cast<String>().toList();

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

  String get shortDisplayName {
    final first = firstName?.trim() ?? '';
    return first.isNotEmpty ? first : 'Client';
  }
}
