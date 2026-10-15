import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:dineroo_mobile/shared/enums/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User', () {
    test('parses token user view, role, organization, and temporary pin', () {
      final user = User.fromToken({
        'sub': 'user-1',
        'given_name': 'Aminata',
        'family_name': 'Diallo',
        'preferred_username': '620000000',
        'resource_access': {
          'user-service-client': {
            'roles': ['RESTAURANT_MANAGER'],
          },
        },
        'organization-resto': {
          'Le Resto': {'id': 'restaurant-1'},
        },
      });

      expect(user.id, 'user-1');
      expect(user.firstName, 'Aminata');
      expect(user.lastName, 'Diallo');
      expect(user.phoneNumber, '620000000');
      expect(user.userRoleEnum, UserRole.restaurantManager);
      expect(user.organization?.id, 'restaurant-1');
      expect(user.organization?.name, 'Le Resto');
      expect(user.isTemporaryPin, isFalse);
    });

    test('uses safe defaults for missing token sections', () {
      final user = User.fromToken({});

      expect(user.id, '');
      expect(user.role, 'CUSTOMER');
      expect(user.userRoleEnum, UserRole.customer);
      expect(user.organization?.id, '');
      expect(user.organization?.name, 'Mon Restaurant');
      expect(user.isTemporaryPin, isFalse);
    });

    test(
      'prefers user-service-client role over dineroo-app and realm roles',
      () {
        final user = User.fromToken({
          'resource_access': {
            'user-service-client': {
              'roles': ['DRIVER'],
            },
            'dineroo-app': {
              'roles': ['CUSTOMER'],
            },
          },
          'realm_access': {
            'roles': ['RESTAURANT_MANAGER'],
          },
        });

        expect(user.role, 'DRIVER');
        expect(user.userRoleEnum, UserRole.driver);
      },
    );

    test('falls back to dineroo-app role when user-service role is absent', () {
      final user = User.fromToken({
        'resource_access': {
          'dineroo-app': {
            'roles': ['restaurant-manager'],
          },
        },
      });

      expect(user.role, 'RESTAURANT_MANAGER');
      expect(user.userRoleEnum, UserRole.restaurantManager);
    });

    test('falls back to realm role and ignores offline roles', () {
      final user = User.fromToken({
        'realm_access': {
          'roles': ['offline_access', 'GUEST'],
        },
      });

      expect(user.role, 'GUEST');
      expect(user.userRoleEnum, UserRole.guest);
    });

    test('copyWith updates selected fields and keeps others', () {
      final user = User(
        id: 'user-1',
        firstName: 'Aminata',
        lastName: 'Diallo',
        phoneNumber: '620000000',
        role: 'CUSTOMER',
        isTemporaryPin: false,
      );

      final updated = user.copyWith(firstName: 'Mariama', isTemporaryPin: true);

      expect(updated.id, 'user-1');
      expect(updated.firstName, 'Mariama');
      expect(updated.lastName, 'Diallo');
      expect(updated.isTemporaryPin, isTrue);
    });

    test(
      'exposes courier status helpers from auth response and token claims',
      () {
        final rejected = User(
          id: 'driver-1',
          firstName: 'Aminata',
          lastName: 'Diallo',
          phoneNumber: '620000000',
          role: 'GUEST',
          isTemporaryPin: false,
          courierStatus: 'rejected',
        );
        final missingFile = rejected.copyWith(
          id: 'driver-2',
          courierStatus: 'ID_FILE_MISSING',
        );
        final pending = User.fromToken({
          'resource_access': {
            'user-service-client': {
              'roles': ['GUEST'],
            },
          },
          'courierStatus': 'PENDING',
        });

        expect(rejected.isRejectedCourier, isTrue);
        expect(rejected.isMissingCourierFile, isFalse);
        expect(missingFile.isMissingCourierFile, isTrue);
        expect(missingFile.isRejectedCourier, isFalse);
        expect(pending.courierStatus, 'PENDING');
        expect(pending.isRejectedCourier, isFalse);
        expect(pending.isMissingCourierFile, isFalse);
      },
    );
  });
}
