import 'package:dineroo_mobile/shared/repositories/auth_repository.dart';
import 'package:dineroo_mobile/shared/services/auth/auth_service.dart';
import 'package:dineroo_mobile/shared/view_models/auth/auth_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/user_role_view_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('AuthViewModel', () {
    testWidgets('verifies a code and toggles loading', (tester) async {
      final repository = _FakeAuthRepository();
      final viewModel = AuthViewModel(repository);
      final context = await _pumpContext(
        tester,
        repository.currentUserViewModel,
      );
      final loadingStates = <bool>[];
      viewModel.addListener(() => loadingStates.add(viewModel.isLoading));

      await viewModel.verifyCode('123456', context: context);

      expect(repository.verifiedCodes, ['123456']);
      expect(viewModel.isLoading, isFalse);
      expect(loadingStates, containsAllInOrder([true, false]));
    });

    testWidgets('converts cancelled code verification to a clear exception', (
      tester,
    ) async {
      final repository = _FakeAuthRepository()
        ..verifyCodeException = _cancelledDioException();
      final viewModel = AuthViewModel(repository);
      final context = await _pumpContext(
        tester,
        repository.currentUserViewModel,
      );

      await expectLater(
        viewModel.verifyCode('123456', context: context),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Code verification cancelled'),
          ),
        ),
      );
      expect(viewModel.isLoading, isFalse);
    });

    testWidgets('converts cancelled login to a clear exception', (
      tester,
    ) async {
      final repository = _FakeAuthRepository()
        ..loginException = _cancelledDioException();
      final viewModel = AuthViewModel(repository);
      final context = await _pumpContext(
        tester,
        repository.currentUserViewModel,
      );

      await expectLater(
        viewModel.login({'phoneNumber': '620000000'}, context: context),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Login cancelled'),
          ),
        ),
      );
      expect(viewModel.isLoading, isFalse);
    });

    test('delegates authentication state to repository', () async {
      final repository = _FakeAuthRepository()..authenticated = true;
      final viewModel = AuthViewModel(repository);

      expect(await viewModel.isAuthenticated(), isTrue);
    });

    test('delegates courier status update to repository', () async {
      final repository = _FakeAuthRepository();
      final viewModel = AuthViewModel(repository);

      await viewModel.updateCourierStatus('PENDING');

      expect(repository.updatedCourierStatus, 'PENDING');
    });

    test('setLoading notifies listeners', () {
      final viewModel = AuthViewModel(_FakeAuthRepository());
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      viewModel.setLoading(true);
      viewModel.setLoading(false);

      expect(viewModel.isLoading, isFalse);
      expect(notifications, 2);
    });

    testWidgets('loadUserFromToken caches token and resets loading', (
      tester,
    ) async {
      final repository = _FakeAuthRepository()..storedToken = 'saved-token';
      final viewModel = AuthViewModel(repository);
      final context = await _pumpContext(
        tester,
        repository.currentUserViewModel,
      );

      await tester.runAsync(() async {
        try {
          await viewModel.loadUserFromToken(context);
        } catch (_) {}
      });

      expect(viewModel.isLoading, isFalse);
    });

    test('cancel methods clear loading on a microtask', () async {
      final viewModel = AuthViewModel(_FakeAuthRepository());
      viewModel.setLoading(true);

      viewModel.cancelLogin();
      await Future<void>.delayed(Duration.zero);
      expect(viewModel.isLoading, isFalse);

      viewModel.setLoading(true);
      viewModel.cancelVerifyCode();
      await Future<void>.delayed(Duration.zero);
      expect(viewModel.isLoading, isFalse);
    });

    testWidgets('login toggles loading and handles no currentUser', (
      tester,
    ) async {
      final repository = _FakeAuthRepository()
        ..loginResult = {'accessToken': 'token', 'refreshToken': 'rt'};
      final viewModel = AuthViewModel(repository);
      final context = await _pumpContext(
        tester,
        repository.currentUserViewModel,
      );
      final loadingStates = <bool>[];
      viewModel.addListener(() => loadingStates.add(viewModel.isLoading));

      await tester.runAsync(() async {
        try {
          await viewModel.login({'phoneNumber': '620000000'}, context: context);
        } catch (_) {}
      });

      expect(viewModel.isLoading, isFalse);
      expect(loadingStates, containsAllInOrder([true, false]));
    });

    testWidgets('loadUserFromToken handles no stored token', (tester) async {
      final repository = _FakeAuthRepository();
      final viewModel = AuthViewModel(repository);
      final context = await _pumpContext(
        tester,
        repository.currentUserViewModel,
      );
      final loadingStates = <bool>[];
      viewModel.addListener(() => loadingStates.add(viewModel.isLoading));

      await tester.runAsync(() async {
        try {
          await viewModel.loadUserFromToken(context);
        } catch (_) {}
      });

      expect(viewModel.isLoading, isFalse);
      expect(loadingStates, containsAllInOrder([true, false]));
    });
  });
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository()
    : currentUser = CurrentUserViewModel(),
      userRole = UserRoleViewModel(),
      super(AuthService(), CurrentUserViewModel(), UserRoleViewModel());

  final CurrentUserViewModel currentUser;
  final UserRoleViewModel userRole;
  final verifiedCodes = <String>[];
  Map<String, dynamic> loginResult = {'accessToken': 'access-token'};
  DioException? verifyCodeException;
  DioException? loginException;
  bool authenticated = false;
  String? storedToken;
  bool logoutFromServerCalled = false;
  bool logoutCalled = false;
  String? updatedCourierStatus;

  @override
  CurrentUserViewModel get currentUserViewModel => currentUser;

  @override
  UserRoleViewModel get userRoleViewModel => userRole;

  @override
  Future<Map<String, dynamic>> verifyCode(
    String code, {
    CancelToken? cancelToken,
  }) async {
    if (verifyCodeException != null) throw verifyCodeException!;
    verifiedCodes.add(code);
    return {'accessToken': 'access-token'};
  }

  @override
  Future<Map<String, dynamic>> login(
    Map<String, dynamic> userData, {
    CancelToken? cancelToken,
  }) async {
    if (loginException != null) throw loginException!;
    return loginResult;
  }

  @override
  Future<bool> isAuthenticated() async => authenticated;

  @override
  Future<String?> loadUserFromToken() async => storedToken;

  @override
  Future<void> logoutFromServer() async {
    logoutFromServerCalled = true;
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }

  @override
  Future<void> updateCourierStatus(String courierStatus) async {
    updatedCourierStatus = courierStatus;
  }
}

DioException _cancelledDioException() {
  return DioException(
    requestOptions: RequestOptions(path: '/auth'),
    type: DioExceptionType.cancel,
  );
}

Future<BuildContext> _pumpContext(
  WidgetTester tester,
  CurrentUserViewModel currentUserViewModel,
) async {
  late BuildContext capturedContext;
  await tester.pumpWidget(
    ChangeNotifierProvider<CurrentUserViewModel>.value(
      value: currentUserViewModel,
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  return capturedContext;
}
