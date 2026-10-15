import 'package:dineroo_mobile/driver/enums/driver_status.dart';

class DriverStatusResponseDto {
  final String driverId;
  final DriverStatus status;

  DriverStatusResponseDto({required this.driverId, required this.status});

  factory DriverStatusResponseDto.fromJson(Map<String, dynamic> json) {
    return DriverStatusResponseDto(
      driverId: (json['driverId'] ?? '').toString(),
      status: DriverStatus.fromApi(json['status']?.toString()),
    );
  }
}
