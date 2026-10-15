import 'dart:io';

import 'package:dineroo_mobile/customer/models/domain/organization.dart';
import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:dineroo_mobile/shared/repositories/auth_repository.dart';
import 'package:dineroo_mobile/shared/repositories/user_repository.dart';
import 'package:dineroo_mobile/shared/services/auth/auth_service.dart';
import 'package:dineroo_mobile/shared/services/user/user_service.dart';
import 'package:dineroo_mobile/shared/view_models/auth/auth_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/user_role_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/user_view_model.dart';
import 'package:dineroo_mobile/shared/views/profile/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('profile_view_test_');
    Hive.init(tempDir.path);
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.test');
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('renders current user profile and disabled fields', (
    tester,
  ) async {
    await tester.pumpWidget(_Harness(user: _user()));

    expect(find.text('Déconnexion'), findsOneWidget);
    expect(find.text('MODIFIER'), findsOneWidget);
    expect(find.text('Changer le code PIN'), findsOneWidget);
    expect(find.text('PRÉNOM'), findsOneWidget);
    expect(find.text('NOM'), findsOneWidget);
    expect(find.text('TÉLÉPHONE'), findsOneWidget);

    final firstNameField = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(firstNameField.enabled, isFalse);
  });

  testWidgets('shows manager restaurant settings entry', (tester) async {
    await tester.pumpWidget(_Harness(user: _user(role: 'RESTAURANT_MANAGER')));

    expect(find.text('Changer les horaires du restaurant'), findsOneWidget);
  });

  testWidgets('toggles edit mode and cancels unchanged profile', (
    tester,
  ) async {
    await tester.pumpWidget(_Harness(user: _user()));

    await tester.tap(find.text('MODIFIER'));
    await tester.pump();

    expect(find.text('ENREGISTRER'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField).first).enabled,
      isTrue,
    );

    await tester.tap(find.text('ENREGISTRER'));
    await tester.pump();

    expect(find.text('MODIFIER'), findsOneWidget);
  });

  testWidgets('updates changed profile through user view model', (
    tester,
  ) async {
    final userService = _FakeUserService();
    final currentUserVM = CurrentUserViewModel()..setUser(_user());

    await tester.pumpWidget(
      _Harness(currentUserVM: currentUserVM, userService: userService),
    );

    await tester.tap(find.text('MODIFIER'));
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), 'Mariama');
    await tester.tap(find.text('ENREGISTRER'));
    await tester.pump();

    expect(userService.updatedUserId, 'user-1');
    expect(userService.updatedFirstName, 'Mariama');
    expect(currentUserVM.currentUser?.firstName, 'Mariama');
    expect(find.text('Profil mis à jour avec succès.'), findsOneWidget);
  });

  testWidgets('renders reconnect state when no user is cached', (tester) async {
    await tester.pumpWidget(_Harness(user: null));

    expect(find.text('Impossible de charger votre profil.'), findsOneWidget);
    expect(find.text('Se reconnecter'), findsOneWidget);
    expect(find.text('MODIFIER'), findsNothing);
  });
}

class _Harness extends StatelessWidget {
  _Harness({
    User? user,
    CurrentUserViewModel? currentUserVM,
    _FakeUserService? userService,
  }) : currentUserVM = currentUserVM ?? CurrentUserViewModel(),
       userService = userService ?? _FakeUserService() {
    if (user != null) this.currentUserVM.setUser(user);
  }

  final CurrentUserViewModel currentUserVM;
  final _FakeUserService userService;

  @override
  Widget build(BuildContext context) {
    final userRoleVM = UserRoleViewModel();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CurrentUserViewModel>.value(
          value: currentUserVM,
        ),
        ChangeNotifierProvider<UserRoleViewModel>.value(value: userRoleVM),
        ChangeNotifierProvider<AuthViewModel>(
          create: (_) => AuthViewModel(
            AuthRepository(AuthService(), currentUserVM, userRoleVM),
          ),
        ),
        ChangeNotifierProvider<UserViewModel>(
          create: (_) => UserViewModel(UserRepository(service: userService)),
        ),
      ],
      child: const MaterialApp(home: ProfileView()),
    );
  }
}

class _FakeUserService extends UserService {
  String? updatedUserId;
  String? updatedFirstName;
  String? updatedLastName;
  String? updatedTelephone;

  @override
  Future<void> updateUser({
    required String userId,
    required String firstName,
    required String lastName,
    required String telephone,
  }) async {
    updatedUserId = userId;
    updatedFirstName = firstName;
    updatedLastName = lastName;
    updatedTelephone = telephone;
  }
}

User _user({String role = 'CUSTOMER'}) {
  return User(
    id: 'user-1',
    firstName: 'Aminata',
    lastName: 'Diallo',
    phoneNumber: '+224620000000',
    role: role,
    isTemporaryPin: false,
    organization: Organization(id: 'restaurant-1', name: 'Chez Mariam'),
  );
}
