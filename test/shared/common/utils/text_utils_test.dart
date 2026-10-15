import 'package:dineroo_mobile/shared/common/utils/text_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('text_utils', () {
    test('capitalizes words', () {
      expect(capitalize('aminata'), 'Aminata');
      expect(capitalize('AMINATA'), 'Aminata');
      expect(capitalize(''), '');
    });

    test('extracts first non-empty name part with fallback', () {
      expect(extractFirstName('  Mamadou   Bah  '), 'Mamadou');
      expect(extractFirstName(null), 'Client');
      expect(extractFirstName(' ', fallback: 'Livreur'), 'Livreur');
    });
  });
}
