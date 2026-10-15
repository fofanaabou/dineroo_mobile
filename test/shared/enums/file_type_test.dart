import 'package:dineroo_mobile/shared/enums/file_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FileType', () {
    test('exposes API values', () {
      expect(FileType.profilePhoto.value, 'PROFILE_PHOTO');
      expect(FileType.identityCard.value, 'ID');
    });
  });
}
