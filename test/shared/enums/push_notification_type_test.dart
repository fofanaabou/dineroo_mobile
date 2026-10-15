import 'package:dineroo_mobile/shared/enums/push_notification_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PushNotificationType', () {
    test('parses known wire values', () {
      for (final type in PushNotificationType.values) {
        expect(PushNotificationType.fromWireValue(type.wireValue), type);
      }
    });

    test('returns null for unsupported wire values', () {
      expect(PushNotificationType.fromWireValue(null), isNull);
      expect(PushNotificationType.fromWireValue('unsupported'), isNull);
    });
  });
}
