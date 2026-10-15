@TestOn('browser')
library;

import 'package:dineroo_mobile/shared/common/config/local_storage_initializer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('opens the app boxes in the browser', () async {
    await initializeLocalStorage();

    expect(Hive.isBoxOpen('recentSearches'), isTrue);
    expect(Hive.isBoxOpen('deliveryAddressBox'), isTrue);
    expect(Hive.isBoxOpen('cartBox'), isTrue);
  });
}
