import 'package:dineroo_mobile/driver/models/dto/assign_driver_response_dto.dart';
import 'package:dineroo_mobile/driver/models/domain/driver_delivery.dart';
import 'package:dineroo_mobile/driver/services/delivery/driver_delivery_service.dart';

class DriverDeliveryRepository {
  final DriverDeliveryService _service;

  DriverDeliveryRepository({required DriverDeliveryService service})
    : _service = service;

  Future<AssignDriverResponseDto> assignDriver({
    required String driverId,
    required String deliveryId,
  }) async {
    final json = await _service.assignDriver(
      driverId: driverId,
      deliveryId: deliveryId,
    );

    return AssignDriverResponseDto.fromJson(json);
  }

  Future<List<DriverDelivery>> fetchDeliveriesByDriverId({
    required String driverId,
    List<String>? statuses,
  }) async {
    final json = await _service.fetchDeliveriesByDriverId(
      driverId: driverId,
      statuses: statuses,
    );

    return json
        .whereType<Map<String, dynamic>>()
        .map(DriverDelivery.fromJson)
        .toList();
  }

  Future<void> updateDeliveryStatus({
    required String deliveryId,
    required String status,
    String? driverId,
    double? latitude,
    double? longitude,
  }) async {
    await _service.updateDeliveryStatus(
      deliveryId: deliveryId,
      status: status,
      driverId: driverId,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
