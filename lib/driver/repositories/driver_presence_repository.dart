import 'package:dineroo_mobile/driver/enums/driver_status.dart';
import 'package:dineroo_mobile/driver/models/dto/driver_status_response_dto.dart';
import 'package:dineroo_mobile/driver/services/driver_presence/driver_presence_service.dart';

class DriverPresenceRepository {
  final DriverPresenceService _service;

  DriverPresenceRepository({required DriverPresenceService service})
    : _service = service;

  Future<DriverStatus> setStatus({
    required String driverId,
    required DriverStatus status,
  }) async {
    final json = await _service.updateDriverStatus(
      driverId: driverId,
      status: status.apiValue,
    );

    final dto = DriverStatusResponseDto.fromJson(json);
    return dto.status;
  }

  Future<DriverStatus> fetchStatus({required String driverId}) async {
    final json = await _service.fetchDriverById(driverId: driverId);
    return DriverStatus.fromApi(json['status']?.toString());
  }
}
