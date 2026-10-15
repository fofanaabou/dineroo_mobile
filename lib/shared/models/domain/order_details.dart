class DriverDetails {
  final String id;
  final String firstName;
  final String? lastName;
  final String phoneNumber;

  const DriverDetails({
    required this.id,
    required this.firstName,
    this.lastName,
    required this.phoneNumber,
  });

  String get fullName {
    final parts =
        [
          firstName.trim(),
          lastName?.trim(),
        ].where((e) => e != null && e.isNotEmpty).cast<String>().toList();

    final full = parts.join(' ');
    return full.isNotEmpty ? full : 'Livreur';
  }
}

class CustomerDetails {
  final String phone;
  final String? name;

  const CustomerDetails({required this.phone, this.name});

  String get displayName {
    final value = name?.trim();
    return (value != null && value.isNotEmpty) ? value : 'Client';
  }
}

class OrderDetails {
  final String orderId;
  final DriverDetails? driverDetails;
  final CustomerDetails? customerDetails;

  const OrderDetails({
    required this.orderId,
    this.driverDetails,
    this.customerDetails,
  });

  bool get hasAssignedDriver =>
      driverDetails != null && driverDetails!.fullName.trim().isNotEmpty;
}
