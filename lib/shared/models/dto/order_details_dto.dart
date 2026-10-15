import 'package:dineroo_mobile/shared/models/domain/order_details.dart';

class OrderDetailsDto {
  final String orderId;
  final DriverDetailsDto? driverDetails;
  final CustomerDetailsDto? customerDetails;

  OrderDetailsDto({
    required this.orderId,
    this.driverDetails,
    this.customerDetails,
  });

  factory OrderDetailsDto.fromJson(Map<String, dynamic> json) {
    return OrderDetailsDto(
      orderId: json['orderId']?.toString() ?? '',
      driverDetails:
          json['driverDetails'] != null
              ? DriverDetailsDto.fromJson(json['driverDetails'])
              : null,
      customerDetails:
          json['customerDetails'] != null
              ? CustomerDetailsDto.fromJson(json['customerDetails'])
              : null,
    );
  }

  OrderDetails toDomain() {
    return OrderDetails(
      orderId: orderId,
      driverDetails: driverDetails?.toDomain(),
      customerDetails: customerDetails?.toDomain(),
    );
  }
}

class DriverDetailsDto {
  final String id;
  final String firstName;
  final String? lastName;
  final String phoneNumber;

  DriverDetailsDto({
    required this.id,
    required this.firstName,
    this.lastName,
    required this.phoneNumber,
  });

  factory DriverDetailsDto.fromJson(Map<String, dynamic> json) {
    return DriverDetailsDto(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString(), // nullable maintenant
      phoneNumber: json['phoneNumber']?.toString() ?? '',
    );
  }

  DriverDetails toDomain() {
    return DriverDetails(
      id: id,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
    );
  }
}

class CustomerDetailsDto {
  final String phone;
  final String? name;

  CustomerDetailsDto({required this.phone, this.name});

  factory CustomerDetailsDto.fromJson(Map<String, dynamic> json) {
    return CustomerDetailsDto(
      phone: json['phone']?.toString() ?? '',
      name: json['name']?.toString(),
    );
  }

  CustomerDetails toDomain() {
    return CustomerDetails(phone: phone, name: name);
  }
}
