import 'package:dineroo_mobile/shared/enums/user_role.dart';
import 'package:dineroo_mobile/shared/services/auth/auth_service.dart';
import 'package:dineroo_mobile/shared/repositories/auth_repository.dart';
import 'package:dineroo_mobile/shared/view_models/auth/auth_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/user_role_view_model.dart';
import 'package:dineroo_mobile/shared/views/auth/login_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('LoginView', () {
    testWidgets('renders customer login form with sign-up', (tester) async {
      await tester.pumpWidget(_pumpLoginView(UserRole.customer));
      await tester.pump();

      expect(find.text('Connexion Client'), findsOneWidget);
      expect(find.text('SE CONNECTER'), findsOneWidget);
      expect(find.text('Pas encore inscrit ?'), findsOneWidget);
      expect(find.text('Créer un compte'), findsOneWidget);
      expect(find.text('Code PIN oublié'), findsOneWidget);
    });

    testWidgets('renders driver login form with sign-up', (tester) async {
      await tester.pumpWidget(_pumpLoginView(UserRole.driver));
      await tester.pump();

      expect(find.text('Connexion Livreur'), findsOneWidget);
      expect(find.text('Pas encore inscrit ?'), findsOneWidget);
    });

    testWidgets('renders restaurant manager form without sign-up',
        (tester) async {
      await tester.pumpWidget(_pumpLoginView(UserRole.restaurantManager));
      await tester.pump();

      expect(find.text('Espace Restaurant'), findsOneWidget);
      expect(find.text('Créer un compte'), findsNothing);
      expect(find.textContaining('Bienvenue sur Dineroo'), findsOneWidget);
    });

    testWidgets('disables form fields and buttons while loading',
        (tester) async {
      final authVM = AuthViewModel(
        AuthRepository(AuthService(), CurrentUserViewModel(), UserRoleViewModel()),
      );
      authVM.setLoading(true);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CurrentUserViewModel>.value(
              value: CurrentUserViewModel(),
            ),
            ChangeNotifierProvider<UserRoleViewModel>.value(
              value: UserRoleViewModel(),
            ),
            ChangeNotifierProvider<AuthViewModel>.value(value: authVM),
          ],
          child: const MaterialApp(home: LoginView(selectedRole: UserRole.customer)),
        ),
      );
      await tester.pump();

      final phoneFields = find.byType(TextFormField);
      expect(tester.widgetList(phoneFields).every((w) => (w as TextFormField).enabled == false), isTrue);
      expect(find.text('Code PIN oublié'), findsOneWidget);
    });
  });
}

Widget _pumpLoginView(UserRole role) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<CurrentUserViewModel>.value(
        value: CurrentUserViewModel(),
      ),
      ChangeNotifierProvider<UserRoleViewModel>.value(
        value: UserRoleViewModel(),
      ),
      ChangeNotifierProvider<AuthViewModel>(
        create: (_) => AuthViewModel(
          AuthRepository(AuthService(), CurrentUserViewModel(), UserRoleViewModel()),
        ),
      ),
    ],
    child: MaterialApp(home: LoginView(selectedRole: role)),
  );
}
