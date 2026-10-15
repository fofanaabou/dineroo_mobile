import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:dineroo_mobile/customer/repositories/restaurant_repository.dart';
import 'package:dineroo_mobile/customer/services/restaurant/restaurant_list_service.dart';
import 'package:dineroo_mobile/customer/services/restaurant/restaurant_service.dart';
import 'package:dineroo_mobile/driver/repositories/driver_delivery_repository.dart';
import 'package:dineroo_mobile/driver/repositories/driver_order_repository.dart';
import 'package:dineroo_mobile/driver/repositories/driver_presence_repository.dart';
import 'package:dineroo_mobile/driver/services/delivery/driver_delivery_service.dart';
import 'package:dineroo_mobile/driver/services/driver_presence/driver_presence_service.dart';
import 'package:dineroo_mobile/driver/view_models/driver_home_view_model.dart';
import 'package:dineroo_mobile/shared/enums/user_role.dart';
import 'package:dineroo_mobile/shared/enums/verify_code_flow.dart';
import 'package:dineroo_mobile/shared/repositories/auth_repository.dart';
import 'package:dineroo_mobile/shared/repositories/order_details_repository.dart';
import 'package:dineroo_mobile/shared/repositories/user_repository.dart';
import 'package:dineroo_mobile/shared/services/auth/auth_service.dart';
import 'package:dineroo_mobile/shared/services/order/order_details_service.dart';
import 'package:dineroo_mobile/shared/services/order/shared_order_service.dart';
import 'package:dineroo_mobile/shared/services/user/user_service.dart';
import 'package:dineroo_mobile/shared/view_models/auth/auth_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/user_role_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/user_view_model.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_verify_code_input.dart';
import 'package:dineroo_mobile/shared/views/auth/forgot_pin_view.dart';
import 'package:dineroo_mobile/shared/views/auth/sign_up_view.dart';
import 'package:dineroo_mobile/shared/views/auth/verify_code_view.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('Auth views', () {
    testWidgets('SignUpView renders customer registration fields', (
      tester,
    ) async {
      await tester.pumpWidget(
        _AuthHarness(child: const SignUpView(selectedRole: UserRole.customer)),
      );

      expect(find.text('Créer un compte'), findsOneWidget);
      expect(find.text('Veuillez renseigner vos informations'), findsOneWidget);
      expect(find.text('PRÉNOM'), findsOneWidget);
      expect(find.text('NOM'), findsOneWidget);
      expect(find.text('TÉLÉPHONE'), findsOneWidget);
      expect(find.text('CODE PIN'), findsOneWidget);
      expect(find.text('SUIVANT'), findsOneWidget);
      expect(find.text('Vous avez déjà un compte ?'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);
    });

    testWidgets('ForgotPinView renders reset fields for a customer', (
      tester,
    ) async {
      await tester.pumpWidget(
        _AuthHarness(
          child: const ForgotPinView(selectedRole: UserRole.customer),
        ),
      );

      expect(find.text('Code PIN oublié'), findsOneWidget);
      expect(find.text('Veuillez saisir vos informations'), findsOneWidget);
      expect(find.text('TÉLÉPHONE'), findsOneWidget);
      expect(find.text('NOUVEAU CODE PIN'), findsOneWidget);
      expect(find.text('CONFIRMER LE CODE PIN'), findsOneWidget);
      expect(find.text('RÉINITIALISER'), findsOneWidget);
      expect(find.text('Pas encore inscrit ?'), findsOneWidget);
      expect(find.text('Créer un compte'), findsOneWidget);
    });

    testWidgets(
      'ForgotPinView adapts title and links for temporary manager pin',
      (tester) async {
        await tester.pumpWidget(
          _AuthHarness(
            child: const ForgotPinView(
              selectedRole: UserRole.restaurantManager,
              isTemporaryPin: true,
            ),
          ),
        );

        expect(find.text('Changer code PIN'), findsOneWidget);
        expect(find.text('Créer un compte'), findsNothing);
        expect(find.text('RÉINITIALISER'), findsOneWidget);
      },
    );

    testWidgets(
      'ForgotPinView puts connected driver offline before resetting pin',
      (tester) async {
        final userService = _FakeUserService();
        final authViewModel = _FakeAuthViewModel();
        final driverHomeViewModel = _FakeDriverHomeViewModel();

        await tester.pumpWidget(
          _AuthHarness(
            userService: userService,
            authViewModel: authViewModel,
            driverHomeViewModel: driverHomeViewModel,
            currentUser: User(
              id: 'driver-1',
              firstName: 'A',
              lastName: 'B',
              phoneNumber: '620000000',
              role: 'DRIVER',
              isTemporaryPin: false,
            ),
            child: const ForgotPinView(selectedRole: UserRole.driver),
          ),
        );

        await tester.enterText(find.byType(TextFormField).at(0), '620000000');
        await tester.enterText(find.byType(TextFormField).at(1), '1234');
        await tester.enterText(find.byType(TextFormField).at(2), '1234');
        await tester.ensureVisible(find.text('RÉINITIALISER'));
        await tester.tap(find.text('RÉINITIALISER'));
        await tester.pump();
        await tester.pump();

        _completeVerificationCode(tester);
        await tester.pumpAndSettle();

        expect(driverHomeViewModel.resetServerCallCount, 1);
        expect(userService.lastResetUserId, 'driver-1');
        expect(userService.lastResetIdPin, '1234');
        expect(authViewModel.logoutLocalCallCount, 1);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 1));
      },
    );

    testWidgets('VerifyCodeView renders phone and disabled resend countdown', (
      tester,
    ) async {
      await tester.pumpWidget(
        _AuthHarness(
          child: const VerifyCodeView(
            flow: VerifyCodeFlow.resetPin,
            userData: {'telephone': '620000000'},
          ),
        ),
      );

      expect(find.text('Vérification'), findsOneWidget);
      expect(find.byType(RichText), findsWidgets);
      expect(find.text('CODE'), findsOneWidget);
      expect(find.text('Renvoyer dans 30s'), findsOneWidget);
      expect(find.text('VÉRIFIER'), findsOneWidget);

      await tester.pump(const Duration(seconds: 31));
      expect(find.text('Renvoyer'), findsOneWidget);
    });

    testWidgets(
      'VerifyCodeView changePhone flow calls validateCode on verify',
      (tester) async {
        final fake = _FakeUserService();
        await tester.pumpWidget(
          _AuthHarness(
            userService: fake,
            currentUser: User(
              id: 'user-1',
              firstName: 'A',
              lastName: 'B',
              phoneNumber: '620000000',
              role: 'CUSTOMER',
              isTemporaryPin: false,
            ),
            child: const VerifyCodeView(
              flow: VerifyCodeFlow.changePhone,
              newPhoneNumber: '621111111',
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Vérification'), findsOneWidget);

        _completeVerificationCode(tester);
        await tester.pump();
        await tester.pump();
        await tester.pump();

        expect(fake.validateCallCount, 1);
        expect(fake.lastValidatedUserId, 'user-1');
        expect(fake.lastValidatedCode, '1234');

        await tester.pump(const Duration(seconds: 31));
      },
    );

    testWidgets(
      'VerifyCodeView shows default error when repository swallows message',
      (tester) async {
        final fake = _FakeUserService()
          ..validateErrorMessage = 'Code invalide ou expir\u00e9'
          ..reset();
        await tester.pumpWidget(
          _AuthHarness(
            userService: fake,
            currentUser: User(
              id: 'user-1',
              firstName: 'A',
              lastName: 'B',
              phoneNumber: '620000000',
              role: 'CUSTOMER',
              isTemporaryPin: false,
            ),
            child: const VerifyCodeView(
              flow: VerifyCodeFlow.changePhone,
              newPhoneNumber: '621111111',
            ),
          ),
        );
        await tester.pump();

        _completeVerificationCode(tester);
        await tester.pump();
        await tester.pump();
        await tester.pump();

        expect(
          find.text('Code incorrect. Veuillez r\u00e9essayer.'),
          findsOneWidget,
        );

        await tester.pump(const Duration(seconds: 31));
      },
    );

    testWidgets('VerifyCodeView resends code after countdown for changePhone', (
      tester,
    ) async {
      final fake = _FakeUserService();
      await tester.pumpWidget(
        _AuthHarness(
          userService: fake,
          currentUser: User(
            id: 'user-1',
            firstName: 'A',
            lastName: 'B',
            phoneNumber: '620000000',
            role: 'CUSTOMER',
            isTemporaryPin: false,
          ),
          child: const VerifyCodeView(
            flow: VerifyCodeFlow.changePhone,
            newPhoneNumber: '621111111',
          ),
        ),
      );
      await tester.pump();

      await tester.pump(const Duration(seconds: 31));
      expect(find.text('Renvoyer'), findsOneWidget);

      await tester.tap(find.text('Renvoyer'));
      await tester.pump();
      await tester.pump();

      expect(fake.sendCodeCallCount, 1);
      expect(fake.lastSentUserId, 'user-1');
      expect(fake.lastSentTelephone, '621111111');

      await tester.pump(const Duration(seconds: 31));
    });

    testWidgets('VerifyCodeView shows default error for unknown error string', (
      tester,
    ) async {
      final fake = _FakeUserService()
        ..validateErrorMessage = 'Some unknown error'
        ..reset();
      await tester.pumpWidget(
        _AuthHarness(
          userService: fake,
          currentUser: User(
            id: 'user-1',
            firstName: 'A',
            lastName: 'B',
            phoneNumber: '620000000',
            role: 'CUSTOMER',
            isTemporaryPin: false,
          ),
          child: const VerifyCodeView(
            flow: VerifyCodeFlow.changePhone,
            newPhoneNumber: '621111111',
          ),
        ),
      );
      await tester.pump();

      _completeVerificationCode(tester);
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Code incorrect. Veuillez r\u00e9essayer.'),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 31));
    });

    testWidgets(
      'VerifyCodeView shows default error when repository swallows message',
      (tester) async {
        final fake = _FakeUserService()
          ..validateErrorMessage = 'a d\u00e9j\u00e0 un compte'
          ..reset();
        await tester.pumpWidget(
          _AuthHarness(
            userService: fake,
            currentUser: User(
              id: 'user-1',
              firstName: 'A',
              lastName: 'B',
              phoneNumber: '620000000',
              role: 'CUSTOMER',
              isTemporaryPin: false,
            ),
            child: const VerifyCodeView(
              flow: VerifyCodeFlow.changePhone,
              newPhoneNumber: '621111111',
            ),
          ),
        );
        await tester.pump();

        _completeVerificationCode(tester);
        await tester.pump();
        await tester.pump();
        await tester.pump();

        expect(
          find.text('Code incorrect. Veuillez r\u00e9essayer.'),
          findsOneWidget,
        );

        await tester.pump(const Duration(seconds: 31));
      },
    );

    testWidgets('VerifyCodeView clears error on editing', (tester) async {
      final fake = _FakeUserService()
        ..validateErrorMessage = 'Code invalide ou expiré'
        ..reset();
      await tester.pumpWidget(
        _AuthHarness(
          userService: fake,
          currentUser: User(
            id: 'user-1',
            firstName: 'A',
            lastName: 'B',
            phoneNumber: '620000000',
            role: 'CUSTOMER',
            isTemporaryPin: false,
          ),
          child: const VerifyCodeView(
            flow: VerifyCodeFlow.changePhone,
            newPhoneNumber: '621111111',
          ),
        ),
      );

      await tester.pump();

      _completeVerificationCode(tester);
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Code incorrect. Veuillez réessayer.'), findsWidgets);

      final input = tester.widget<AppVerifyCodeInput>(
        find.byType(AppVerifyCodeInput),
      );
      input.onEditing?.call(true);
      await tester.pump();

      await tester.pump(const Duration(seconds: 31));
    });

    testWidgets(
      'VerifyCodeView shows default error when disabled message swallowed',
      (tester) async {
        final fake = _FakeUserService()
          ..validateErrorMessage = 'Account disabled'
          ..reset();
        await tester.pumpWidget(
          _AuthHarness(
            userService: fake,
            currentUser: User(
              id: 'user-1',
              firstName: 'A',
              lastName: 'B',
              phoneNumber: '620000000',
              role: 'CUSTOMER',
              isTemporaryPin: false,
            ),
            child: const VerifyCodeView(
              flow: VerifyCodeFlow.changePhone,
              newPhoneNumber: '621111111',
            ),
          ),
        );
        await tester.pump();

        _completeVerificationCode(tester);
        await tester.pump();
        await tester.pump();
        await tester.pump();

        expect(
          find.text('Code incorrect. Veuillez r\u00e9essayer.'),
          findsOneWidget,
        );

        await tester.pump(const Duration(seconds: 31));
      },
    );
  });
}

void _completeVerificationCode(WidgetTester tester, [String code = '1234']) {
  tester
      .widget<AppVerifyCodeInput>(find.byType(AppVerifyCodeInput))
      .onCompleted(code);
}

class _AuthHarness extends StatelessWidget {
  final Widget child;
  final User? currentUser;
  final _FakeUserService? userService;
  final AuthViewModel? authViewModel;
  final DriverHomeViewModel? driverHomeViewModel;

  const _AuthHarness({
    required this.child,
    this.currentUser,
    this.userService,
    this.authViewModel,
    this.driverHomeViewModel,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserViewModel = CurrentUserViewModel();
    if (currentUser != null) {
      currentUserViewModel.setUser(currentUser!);
    }
    final userRoleViewModel = UserRoleViewModel();
    final authRepository = AuthRepository(
      AuthService(),
      currentUserViewModel,
      userRoleViewModel,
    );
    final userRepository = UserRepository(
      service: userService ?? _FakeUserService(),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CurrentUserViewModel>.value(
          value: currentUserViewModel,
        ),
        ChangeNotifierProvider<UserRoleViewModel>.value(
          value: userRoleViewModel,
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (_) => authViewModel ?? AuthViewModel(authRepository),
        ),
        ChangeNotifierProvider<UserViewModel>(
          create: (_) => UserViewModel(userRepository),
        ),
        if (driverHomeViewModel != null)
          ChangeNotifierProvider<DriverHomeViewModel>.value(
            value: driverHomeViewModel!,
          ),
      ],
      child: MaterialApp(home: child),
    );
  }
}

class _FakeUserService extends UserService {
  int sendCodeCallCount = 0;
  int validateCallCount = 0;
  int createUserCallCount = 0;
  String? lastSentUserId;
  String? lastSentTelephone;
  String? lastValidatedUserId;
  String? lastValidatedCode;
  String? lastResetUserId;
  String? lastResetIdPin;
  String? validateErrorMessage;
  String? sendErrorMessage;
  String? createErrorMessage;

  void reset() {
    sendCodeCallCount = 0;
    validateCallCount = 0;
    createUserCallCount = 0;
    lastSentUserId = null;
    lastSentTelephone = null;
    lastValidatedUserId = null;
    lastValidatedCode = null;
    lastResetUserId = null;
    lastResetIdPin = null;
  }

  @override
  Future<void> sendVerificationCode({
    required String userId,
    required String telephone,
  }) async {
    sendCodeCallCount++;
    lastSentUserId = userId;
    lastSentTelephone = telephone;
    if (sendErrorMessage != null) throw Exception(sendErrorMessage);
  }

  @override
  Future<void> validateCode({
    required String userId,
    required String code,
  }) async {
    validateCallCount++;
    lastValidatedUserId = userId;
    lastValidatedCode = code;
    if (validateErrorMessage != null) throw Exception(validateErrorMessage);
  }

  @override
  Future<void> createUser(
    Map<String, dynamic> userData, {
    CancelToken? cancelToken,
  }) async {
    createUserCallCount++;
    if (createErrorMessage != null) throw Exception(createErrorMessage);
  }

  @override
  Future<Map<String, dynamic>> getUserByPhone(String telephone) async {
    return {'id': 'user-1'};
  }

  @override
  Future<void> resetCodePinWithId({
    required String userId,
    required String codePin,
  }) async {
    lastResetUserId = userId;
    lastResetIdPin = codePin;
  }
}

class _FakeAuthViewModel extends AuthViewModel {
  _FakeAuthViewModel()
    : super(
        AuthRepository(
          AuthService(),
          CurrentUserViewModel(),
          UserRoleViewModel(),
        ),
      );

  int logoutLocalCallCount = 0;

  @override
  Future<void> logoutLocal(BuildContext context) async {
    logoutLocalCallCount++;
  }
}

class _FakeDriverHomeViewModel extends DriverHomeViewModel {
  _FakeDriverHomeViewModel()
    : super(
        DriverPresenceRepository(service: DriverPresenceService()),
        DriverDeliveryRepository(service: DriverDeliveryService()),
        DriverOrderRepository(
          orderService: SharedOrderService(),
          orderDetailsRepository: OrderDetailsRepository(
            service: OrderDetailsService(),
          ),
        ),
        RestaurantRepository(
          service: RestaurantService(),
          listService: RestaurantListService(),
        ),
        CurrentUserViewModel(),
      );

  int resetServerCallCount = 0;

  @override
  Future<void> resetDriverSessionServer() async {
    resetServerCallCount++;
  }
}
