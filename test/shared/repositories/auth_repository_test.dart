import 'dart:convert';
import 'dart:io';

import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:dineroo_mobile/shared/common/network/dio_client.dart';
import 'package:dineroo_mobile/shared/repositories/auth_repository.dart';
import 'package:dineroo_mobile/shared/services/auth/auth_service.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/user_role_view_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory hiveDir;
  late _FakeAuthService authService;
  late CurrentUserViewModel currentUserViewModel;
  late UserRoleViewModel userRoleViewModel;
  late AuthRepository repository;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('auth_repository_test_');
    Hive.init(hiveDir.path);
    await AuthInterceptor.clearCachedToken();
    authService = _FakeAuthService();
    currentUserViewModel = CurrentUserViewModel();
    userRoleViewModel = UserRoleViewModel();
    repository = AuthRepository(
      authService,
      currentUserViewModel,
      userRoleViewModel,
    );
  });

  tearDown(() async {
    await Hive.close();
    await AuthInterceptor.clearCachedToken();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test(
    'login persists tokens, caches access token, and exposes current user',
    () async {
      final accessToken = _jwt({
        'sub': 'user-1',
        'given_name': 'Aminata',
        'family_name': 'Diallo',
        'preferred_username': '+224620000000',
        'resource_access': {
          'user-service-client': {
            'roles': ['RESTAURANT_MANAGER'],
          },
        },
        'organization-resto': {
          'Chez Aminata': {'id': 'restaurant-1'},
        },
      });
      authService.loginResponse = {
        'accessToken': accessToken,
        'refreshToken': 'refresh-token',
        'idToken': 'id-token',
        'isTemporaryPin': true,
        'courierStatus': 'REJECTED',
      };

      await repository.login({'telephone': '+224620000000'});

      final authBox = await Hive.openBox('auth');
      expect(authBox.get('accessToken'), accessToken);
      expect(authBox.get('refreshToken'), 'refresh-token');
      expect(authBox.get('idToken'), 'id-token');
      expect(authBox.get('isTemporaryPin'), isTrue);
      expect(AuthInterceptor.cachedAccessToken, accessToken);
      expect(authBox.get('courierStatus'), 'REJECTED');
      expect(currentUserViewModel.currentUser?.id, 'user-1');
      expect(currentUserViewModel.currentUser?.firstName, 'Aminata');
      expect(
        currentUserViewModel.currentUser?.organization?.id,
        'restaurant-1',
      );
      expect(currentUserViewModel.currentUser?.isTemporaryPin, isTrue);
      expect(currentUserViewModel.currentUser?.courierStatus, 'REJECTED');
      expect(userRoleViewModel.isRestaurantManager, isTrue);
    },
  );

  test('verifyCode accepts temporaryPin response alias', () async {
    authService.verifyCodeResponse = {
      'accessToken': _jwt({
        'sub': 'user-2',
        'resource_access': {
          'user-service-client': {
            'roles': ['CUSTOMER'],
          },
        },
      }),
      'refreshToken': 'refresh-token',
      'temporaryPin': true,
    };

    await repository.verifyCode('1234');

    expect(currentUserViewModel.currentUser?.id, 'user-2');
    expect(currentUserViewModel.currentUser?.isTemporaryPin, isTrue);
  });

  test(
    'loadUserFromToken restores user and role from stored access token',
    () async {
      final accessToken = _jwt({
        'sub': 'driver-1',
        'resource_access': {
          'user-service-client': {
            'roles': ['DRIVER'],
          },
        },
      });
      final authBox = await Hive.openBox('auth');
      await authBox.put('accessToken', accessToken);
      await authBox.put('isTemporaryPin', true);
      await authBox.put('courierStatus', 'ID_FILE_MISSING');

      final loadedToken = await repository.loadUserFromToken();

      expect(loadedToken, accessToken);
      expect(currentUserViewModel.currentUser?.id, 'driver-1');
      expect(currentUserViewModel.currentUser?.isTemporaryPin, isTrue);
      expect(
        currentUserViewModel.currentUser?.courierStatus,
        'ID_FILE_MISSING',
      );
      expect(currentUserViewModel.currentUser?.isMissingCourierFile, isTrue);
      expect(userRoleViewModel.isDriver, isTrue);
    },
  );

  test(
    'updateCourierStatus persists status and updates current user',
    () async {
      currentUserViewModel.setUser(
        User(
          id: 'driver-1',
          firstName: 'Aminata',
          lastName: 'Diallo',
          phoneNumber: '620000000',
          role: 'GUEST',
          isTemporaryPin: false,
          courierStatus: 'ID_FILE_MISSING',
        ),
      );

      await repository.updateCourierStatus('PENDING');

      final authBox = await Hive.openBox('auth');
      expect(authBox.get('courierStatus'), 'PENDING');
      expect(currentUserViewModel.currentUser?.courierStatus, 'PENDING');
      expect(currentUserViewModel.currentUser?.isMissingCourierFile, isFalse);
    },
  );

  test(
    'logout clears local tokens, cached token, current user, and role',
    () async {
      final authBox = await Hive.openBox('auth');
      await authBox.put('accessToken', 'access-token');
      await authBox.put('refreshToken', 'refresh-token');
      await AuthInterceptor.cacheAccessToken('access-token');
      currentUserViewModel.setUser(
        User(
          id: 'user-1',
          firstName: 'Aminata',
          lastName: 'Diallo',
          phoneNumber: '620000000',
          role: 'CUSTOMER',
          isTemporaryPin: false,
        ),
      );
      userRoleViewModel.setRole(currentUserViewModel.currentUser!.userRoleEnum);

      await repository.logout();

      expect(authBox.isEmpty, isTrue);
      expect(AuthInterceptor.cachedAccessToken, isNull);
      expect(currentUserViewModel.currentUser, isNull);
      expect(userRoleViewModel.role, isNull);
    },
  );

  test('logoutFromServer delegates to AuthService', () async {
    await repository.logoutFromServer();

    expect(authService.logoutCalls, 1);
  });

  test('stored token helpers ignore empty values and update tokens', () async {
    final authBox = await Hive.openBox('auth');
    await authBox.put('accessToken', '');
    await authBox.put('refreshToken', '');
    await authBox.put('idToken', '');

    expect(await repository.getStoredAccessToken(), isNull);
    expect(await repository.getStoredRefreshToken(), isNull);
    expect(await repository.getStoredIdToken(), isNull);
    expect(await repository.isAuthenticated(), isFalse);

    await repository.updateAccessToken('access-token');
    await repository.updateRefreshToken('refresh-token');
    await authBox.put('idToken', 'id-token');

    expect(await repository.getStoredAccessToken(), 'access-token');
    expect(await repository.getStoredRefreshToken(), 'refresh-token');
    expect(await repository.getStoredIdToken(), 'id-token');
    expect(await repository.isAuthenticated(), isTrue);
  });
}

class _FakeAuthService extends AuthService {
  Map<String, dynamic> loginResponse = const {};
  Map<String, dynamic> verifyCodeResponse = const {};
  int logoutCalls = 0;

  @override
  Future<Map<String, dynamic>> login(
    Map<String, dynamic> userData, {
    CancelToken? cancelToken,
  }) async {
    return loginResponse;
  }

  @override
  Future<Map<String, dynamic>> verifyCode(
    String code, {
    CancelToken? cancelToken,
  }) async {
    return verifyCodeResponse;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
  }
}

String _jwt(Map<String, dynamic> payload) {
  String encode(Map<String, dynamic> value) {
    return base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  }

  return '${encode({'alg': 'none', 'typ': 'JWT'})}.${encode(payload)}.';
}
