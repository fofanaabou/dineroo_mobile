import 'package:dineroo_mobile/shared/enums/suspension_reason.dart';
import 'package:dineroo_mobile/shared/models/domain/suspension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SuspensionReason', () {
    test('maps every backend code to its French label', () {
      expect(
        SuspensionReason.fromApiValue('SERVICE_QUALITY'),
        SuspensionReason.serviceQuality,
      );
      expect(
        SuspensionReason.serviceQuality.label,
        'Réclamations qualité / hygiène',
      );
      expect(
        SuspensionReason.fromApiValue('INCOMPLETE_ORDERS').label,
        'Articles manquants dans les commandes livrées',
      );
      expect(
        SuspensionReason.fromApiValue('EXCESSIVE_PREPARATION_TIME').label,
        'Délais de préparation excessifs',
      );
      expect(
        SuspensionReason.fromApiValue('UNRESPONSIVE_TO_ORDERS').label,
        "Ne répond pas aux demandes d'acceptation de commande",
      );
      expect(
        SuspensionReason.fromApiValue('CONTRACT_BREACH').label,
        'Violation des conditions générales',
      );
      expect(SuspensionReason.fromApiValue('OTHER').label, 'Autre');
    });

    test('falls back to a generic label for an unknown reason', () {
      expect(
        SuspensionReason.fromApiValue('SOMETHING_ADDED_LATER'),
        SuspensionReason.other,
      );
      expect(SuspensionReason.fromApiValue(null), SuspensionReason.other);
      expect(SuspensionReason.fromApiValue(''), SuspensionReason.other);
    });
  });

  group('Suspension', () {
    test('parses the API payload', () {
      final suspension = Suspension.fromJson({
        'reason': 'CONTRACT_BREACH',
        'suspendedAt': '2026-08-18T10:15:30Z',
      });

      expect(suspension.reason, SuspensionReason.contractBreach);
      expect(suspension.suspendedAt, DateTime.parse('2026-08-18T10:15:30Z'));
    });

    test('keeps the reason when the timestamp is unusable', () {
      final suspension = Suspension.fromJson({
        'reason': 'SERVICE_QUALITY',
        'suspendedAt': 'not-a-date',
      });

      expect(suspension.reason, SuspensionReason.serviceQuality);
      expect(suspension.suspendedAt, isNull);
    });

    test('describes itself without leaking a note', () {
      final suspension = Suspension.fromJson({
        'reason': 'CONTRACT_BREACH',
        'suspendedAt': '2026-08-18T10:15:30Z',
        'note': 'internal support commentary',
      });

      expect(suspension.toString(), contains('CONTRACT_BREACH'));
      expect(suspension.toString(), isNot(contains('internal')));
    });

    test('reads the optional suspension object of a restaurant payload', () {
      expect(Suspension.fromRestaurantJson(null), isNull);
      expect(Suspension.fromRestaurantJson('SUSPENDED'), isNull);
      expect(
        Suspension.fromRestaurantJson({
          'reason': 'OTHER',
          'suspendedAt': '2026-08-18T10:15:30Z',
        })?.reason,
        SuspensionReason.other,
      );
    });
  });
}
