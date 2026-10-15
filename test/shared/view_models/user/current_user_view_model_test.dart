import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurrentUserViewModel', () {
    test('starts with null currentUser', () {
      final vm = CurrentUserViewModel();
      expect(vm.currentUser, isNull);
    });

    test('setUser stores user and notifies listeners', () {
      final vm = CurrentUserViewModel();
      final user = _testUser();
      var notificationCount = 0;
      vm.addListener(() => notificationCount++);

      vm.setUser(user);

      expect(vm.currentUser, same(user));
      expect(notificationCount, 1);
    });

    test('clear removes user and notifies listeners', () {
      final vm = CurrentUserViewModel();
      vm.setUser(_testUser());
      var notificationCount = 0;
      vm.addListener(() => notificationCount++);

      vm.clear();

      expect(vm.currentUser, isNull);
      expect(notificationCount, 1);
    });
  });
}

User _testUser() => User(
      id: 'u1',
      phoneNumber: '620000000',
      firstName: 'Test',
      lastName: 'User',
      role: 'CUSTOMER',
      isTemporaryPin: false,
    );
