import 'package:dineroo_mobile/driver/enums/driver_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DriverStatus', () {
    test('parses API values with safe fallback', () {
      expect(DriverStatus.fromApi(' online '), DriverStatus.online);
      expect(DriverStatus.fromApi('ON_DELIVERY'), DriverStatus.onDelivery);
      expect(DriverStatus.fromApi('OFFLINE'), DriverStatus.offline);
      expect(DriverStatus.fromApi(null), DriverStatus.offline);
      expect(DriverStatus.fromApi('unsupported'), DriverStatus.offline);
    });

    test('serializes to api value via toString', () {
      expect(DriverStatus.offline.toString(), 'OFFLINE');
      expect(DriverStatus.online.toString(), 'ONLINE');
      expect(DriverStatus.onDelivery.toString(), 'ON_DELIVERY');
    });
  });
}
