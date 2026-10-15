import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:dineroo_mobile/shared/common/helpers/auth_helper.dart';
import 'package:dineroo_mobile/shared/enums/user_role.dart';
import 'package:dineroo_mobile/shared/repositories/auth_repository.dart';
import 'package:dineroo_mobile/shared/repositories/user_repository.dart';
import 'package:dineroo_mobile/shared/services/app_update/app_update_service.dart';
import 'package:dineroo_mobile/shared/services/auth/auth_service.dart';
import 'package:dineroo_mobile/shared/services/user/user_service.dart';
import 'package:dineroo_mobile/shared/view_models/app_update/app_update_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/auth/auth_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/user_role_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/user_view_model.dart';
import 'package:dineroo_mobile/shared/views/auth/identity_upload_view.dart';
import 'package:dineroo_mobile/shared/views/initial_redirect_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('handleDriverAccountAccess', () {
    testWidgets('redirects missing-file couriers to identity upload', (
      tester,
    ) async {
      final authVM = _FakeAuthViewModel();

      await tester.pumpWidget(_Harness(authVM: authVM));
      await tester.tap(find.text('check access'));
      await tester.pumpAndSettle();

      expect(find.byType(IdentityUploadView), findsOneWidget);
      expect(find.text("Ajoutez une pièce d'identité"), findsOneWidget);
      expect(authVM.logoutCalls, 0);
    });

    testWidgets('shows rejected message and logs out rejected couriers', (
      tester,
    ) async {
      final authVM = _FakeAuthViewModel();

      await tester.pumpWidget(
        _Harness(
          authVM: authVM,
          user: _driver(courierStatus: 'REJECTED'),
        ),
      );
      await tester.tap(find.text('check access'));
      await tester.pump();

      expect(
        find.text('Votre compte a été refusé. Veuillez contacter le support.'),
        findsOneWidget,
      );
      expect(find.byType(IdentityUploadView), findsNothing);
      expect(authVM.logoutCalls, 1);
    });

    testWidgets('shows pending message and logs out other guest couriers', (
      tester,
    ) async {
      final authVM = _FakeAuthViewModel();

      await tester.pumpWidget(
        _Harness(
          authVM: authVM,
          user: _driver(courierStatus: 'PENDING'),
        ),
      );
      await tester.tap(find.text('check access'));
      await tester.pump();

      expect(
        find.text('Votre compte est en attente de validation.'),
        findsOneWidget,
      );
      expect(find.byType(IdentityUploadView), findsNothing);
      expect(authVM.logoutCalls, 1);
    });
  });

  group('InitialRedirectView', () {
    testWidgets('keeps missing-file guest couriers on identity upload', (
      tester,
    ) async {
      final authVM = _FakeAuthViewModel()..authenticated = true;
      final currentUserVM = CurrentUserViewModel()
        ..setUser(_driver(courierStatus: 'ID_FILE_MISSING'));
      final roleVM = UserRoleViewModel()..setRole(UserRole.guest);

      await tester.pumpWidget(
        _InitialRedirectHarness(
          authVM: authVM,
          currentUserVM: currentUserVM,
          roleVM: roleVM,
        ),
      );
      await tester.pumpAndSettle();

      expect(authVM.loadUserFromTokenCalls, 1);
      expect(find.byType(IdentityUploadView), findsOneWidget);
      expect(find.text("Ajoutez une pièce d'identité"), findsOneWidget);
      expect(find.text('Qui êtes-vous ?'), findsNothing);
      expect(authVM.logoutCalls, 0);
    });
  });
}

class _Harness extends StatelessWidget {
  const _Harness({required this.authVM, this.user});

  final _FakeAuthViewModel authVM;
  final User? user;

  @override
  Widget build(BuildContext context) {
    final currentUserVM = CurrentUserViewModel();
    if (user != null) currentUserVM.setUser(user!);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CurrentUserViewModel>.value(
          value: currentUserVM,
        ),
        ChangeNotifierProvider<UserRoleViewModel>.value(
          value: UserRoleViewModel(),
        ),
        ChangeNotifierProvider<AuthViewModel>.value(value: authVM),
        ChangeNotifierProvider<UserViewModel>(
          create: (_) =>
              UserViewModel(UserRepository(service: _FakeUserService())),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => handleDriverAccountAccess(
                  context,
                  authVM,
                  user ?? _driver(courierStatus: 'ID_FILE_MISSING'),
                ),
                child: const Text('check access'),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FakeAuthViewModel extends AuthViewModel {
  _FakeAuthViewModel() : super(_FakeAuthRepository());

  int logoutCalls = 0;
  int loadUserFromTokenCalls = 0;
  bool authenticated = false;

  @override
  Future<bool> isAuthenticated() async => authenticated;

  @override
  Future<void> loadUserFromToken(BuildContext context) async {
    loadUserFromTokenCalls++;
  }

  @override
  Future<void> logout(BuildContext context) async {
    logoutCalls++;
  }
}

class _InitialRedirectHarness extends StatelessWidget {
  const _InitialRedirectHarness({
    required this.authVM,
    required this.currentUserVM,
    required this.roleVM,
  });

  final _FakeAuthViewModel authVM;
  final CurrentUserViewModel currentUserVM;
  final UserRoleViewModel roleVM;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppUpdateViewModel>(
          create: (_) => AppUpdateViewModel(_FakeAppUpdateService()),
        ),
        ChangeNotifierProvider<CurrentUserViewModel>.value(
          value: currentUserVM,
        ),
        ChangeNotifierProvider<UserRoleViewModel>.value(value: roleVM),
        ChangeNotifierProvider<AuthViewModel>.value(value: authVM),
        ChangeNotifierProvider<UserViewModel>(
          create: (_) =>
              UserViewModel(UserRepository(service: _FakeUserService())),
        ),
      ],
      child: const MaterialApp(home: InitialRedirectView()),
    );
  }
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository()
    : super(AuthService(), CurrentUserViewModel(), UserRoleViewModel());
}

class _FakeUserService extends UserService {}

class _FakeAppUpdateService extends AppUpdateService {
  @override
  Future<AppUpdateResult> checkForUpdate() async => AppUpdateResult.none();
}

User _driver({required String courierStatus}) {
  return User(
    id: 'driver-1',
    firstName: 'Aminata',
    lastName: 'Diallo',
    phoneNumber: '620000000',
    role: 'GUEST',
    isTemporaryPin: false,
    courierStatus: courierStatus,
  );
}
