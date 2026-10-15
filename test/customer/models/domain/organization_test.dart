import 'package:dineroo_mobile/customer/models/domain/organization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Organization', () {
    test('parses the first supported organization section', () {
      final organization = Organization.fromToken({
        'organizations': {
          'Dineroo Food': {'id': 'org-1'},
        },
      });

      expect(organization.id, 'org-1');
      expect(organization.name, 'Dineroo Food');
    });

    test('uses fallback organization when token has no supported section', () {
      final organization = Organization.fromToken({});

      expect(organization.id, '');
      expect(organization.name, 'Mon Restaurant');
    });

    test('toString contains id and name', () {
      final organization = Organization(id: 'org-1', name: 'Dineroo Food');

      expect(
        organization.toString(),
        'Organization(id: org-1, name: Dineroo Food)',
      );
    });
  });
}
