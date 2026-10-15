import 'package:dineroo_mobile/shared/views/auth/login_view.dart';
import 'package:dineroo_mobile/shared/enums/user_role.dart';
import 'package:dineroo_mobile/shared/repositories/auth_repository.dart';
import 'package:dineroo_mobile/shared/services/auth/auth_service.dart';
import 'package:dineroo_mobile/shared/view_models/auth/auth_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/user_role_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('LoginView shows all required widgets', (
    WidgetTester tester,
  ) async {
    await _pumpLoginView(tester);

    expect(find.text('TÉLÉPHONE'), findsOneWidget);
    expect(find.text('CODE PIN'), findsOneWidget);

    expect(find.text('SE CONNECTER'), findsOneWidget);

    expect(find.text('Code PIN oublié'), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);
  });

  testWidgets('PIN visibility toggle works', (WidgetTester tester) async {
    await _pumpLoginView(tester);

    final toggleIcon = find.byIcon(Icons.visibility_off);
    expect(toggleIcon, findsOneWidget);

    await tester.tap(toggleIcon);
    await tester.pump();

    expect(find.byIcon(Icons.visibility), findsOneWidget);
  });

  testWidgets('Phone and PIN fields accept input', (WidgetTester tester) async {
    await _pumpLoginView(tester);

    final phoneField = find.byType(TextFormField).at(0);
    final pinField = find.byType(TextFormField).at(1);

    await tester.enterText(phoneField, '1234567890');
    await tester.enterText(pinField, '1234');

    final phoneWidget = tester.widget<TextFormField>(phoneField);
    final pinWidget = tester.widget<TextFormField>(pinField);

    expect(phoneWidget.controller?.text, '123 45 67 89');
    expect(pinWidget.controller?.text, '1234');
  });

  testWidgets('Login actions are visible and enabled', (
    WidgetTester tester,
  ) async {
    await _pumpLoginView(tester);

    final forgotPinButton = find.text('Code PIN oublié');
    final signUpButton = find.text('Créer un compte');
    final loginButton = find.text('SE CONNECTER');

    expect(forgotPinButton, findsOneWidget);
    expect(signUpButton, findsOneWidget);
    expect(loginButton, findsOneWidget);
  });
}

Future<void> _pumpLoginView(WidgetTester tester) async {
  final currentUserViewModel = CurrentUserViewModel();
  final userRoleViewModel = UserRoleViewModel();
  final authRepository = AuthRepository(
    AuthService(),
    currentUserViewModel,
    userRoleViewModel,
  );

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CurrentUserViewModel>.value(
          value: currentUserViewModel,
        ),
        ChangeNotifierProvider<UserRoleViewModel>.value(
          value: userRoleViewModel,
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (_) => AuthViewModel(authRepository),
        ),
      ],
      child: const MaterialApp(
        home: LoginView(selectedRole: UserRole.customer),
      ),
    ),
  );
}
