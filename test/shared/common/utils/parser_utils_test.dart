import 'package:dineroo_mobile/shared/common/utils/parser_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseToInt', () {
    test('parses supported numeric values', () {
      expect(parseToInt(12), 12);
      expect(parseToInt('34'), 34);
      expect(parseToInt(56.9), 56);
    });

    test('returns zero for unsupported or invalid values', () {
      expect(parseToInt('not-a-number'), 0);
      expect(parseToInt(null), 0);
      expect(parseToInt(true), 0);
    });
  });

  group('parseToDouble', () {
    test('parses supported numeric values', () {
      expect(parseToDouble(12), 12.0);
      expect(parseToDouble(34.5), 34.5);
      expect(parseToDouble('56.75'), 56.75);
    });

    test('returns zero for unsupported or invalid values', () {
      expect(parseToDouble('not-a-number'), 0.0);
      expect(parseToDouble(null), 0.0);
      expect(parseToDouble(false), 0.0);
    });
  });
}
