class AssignDriverResponseDto {
  final String driverId;
  final String deliveryId;
  final String driverStatus;
  final String deliveryStatus;

  AssignDriverResponseDto({
    required this.driverId,
    required this.deliveryId,
    required this.driverStatus,
    required this.deliveryStatus,
  });

  factory AssignDriverResponseDto.fromJson(Map<String, dynamic> json) {
    return AssignDriverResponseDto(
      driverId: (json['driverId'] ?? '').toString(),
      deliveryId: (json['deliveryId'] ?? '').toString(),
      driverStatus: (json['driverStatus'] ?? '').toString(),
      deliveryStatus: (json['deliveryStatus'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'driverId': driverId,
    'deliveryId': deliveryId,
    'driverStatus': driverStatus,
    'deliveryStatus': deliveryStatus,
  };
}
