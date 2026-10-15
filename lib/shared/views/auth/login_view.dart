import 'package:dineroo_mobile/customer/views/customer_main_view.dart';
import 'package:dineroo_mobile/driver/views/driver_main_view.dart';
import 'package:dineroo_mobile/manager/views/manager_main_view.dart';
import 'package:dineroo_mobile/shared/common/helpers/auth_helper.dart';
import 'package:dineroo_mobile/shared/common/helpers/phone_helper.dart';
import 'package:dineroo_mobile/shared/common/helpers/user_role_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_snackbar.dart';
import 'package:dineroo_mobile/shared/enums/user_role.dart';
import 'package:dineroo_mobile/shared/models/domain/push_notification_payload.dart';
import 'package:dineroo_mobile/shared/services/notification/push_navigation_resolver.dart';
import 'package:dineroo_mobile/shared/services/notification/push_notification_service.dart';
import 'package:dineroo_mobile/shared/view_models/auth/auth_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'sign_up_view.dart';
import 'forgot_pin_view.dart';
import '../location/location_access_view.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_button.dart';
import '../../common/form_fields/phone_field.dart';
import '../../common/form_fields/pin_field.dart';
import 'auth_layout.dart';
import '../../common/helpers/navigation_helper.dart';

class LoginView extends StatefulWidget {
  final UserRole selectedRole;

  const LoginView({super.key, required this.selectedRole});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  bool _obscurePin = true;

  late AuthViewModel _authVM;
  final PushNavigationResolver _pushNavigationResolver =
      const PushNavigationResolver();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authVM = context.read<AuthViewModel>();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    final userData = {
      'telephone': formatPhoneGuinea(_phoneController.text),
      'codePin': _pinController.text,
    };

    try {
      await _authVM.login(userData, context: context);
      if (!mounted) return;

      final selectedRole = widget.selectedRole;
      final currentUser = context.read<CurrentUserViewModel>().currentUser;
      final currentUserRole = currentUser?.userRoleEnum;
      final authVM = context.read<AuthViewModel>();

      if (selectedRole == UserRole.restaurantManager &&
          currentUser?.isTemporaryPin == true) {
        final isTemp = currentUser!.isTemporaryPin;
        navigateTo(
          context,
          ForgotPinView(
            selectedRole: UserRole.restaurantManager,
            isTemporaryPin: isTemp,
          ),
        );
        await authVM.logout(context);
        return;
      }

      if (selectedRole == UserRole.driver &&
          currentUserRole == UserRole.guest) {
        await handleDriverAccountAccess(context, _authVM, currentUser);
        return;
      }

      if (selectedRole != currentUserRole) {
        await _authVM.logout(context);
        if (!mounted) return;

        final selectedRoleLabel = expectedRoleLabel(widget.selectedRole);
        final currentUserRoleLabel = expectedRoleLabel(
          currentUserRole ?? UserRole.customer,
        );

        final roleLabel =
            "Ce compte $selectedRoleLabel n'existe pas. "
            "Si vous êtes $currentUserRoleLabel, merci de revenir en arrière "
            "et choisir l'option JE SUIS UN ${currentUserRoleLabel.toUpperCase()}.";

        AppSnackbar.error(
          context,
          roleLabel,
          duration: const Duration(seconds: 5),
        );
        return;
      }

      if (selectedRole == UserRole.restaurantManager) {
        final pendingPushScreen = _consumePendingPushScreen(currentUser);
        if (pendingPushScreen != null) {
          replaceAll(context, pendingPushScreen);
          return;
        }

        replaceAll(context, const ManagerMainView());
        return;
      }

      final permission = await Geolocator.checkPermission();
      if (!mounted) return;

      final isLocationGranted =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      if (isLocationGranted) {
        final pendingPushScreen = _consumePendingPushScreen(currentUser);
        if (pendingPushScreen != null) {
          replaceAll(context, pendingPushScreen);
          return;
        }

        if (currentUserRole == UserRole.driver) {
          replaceAll(context, const DriverMainView());
        } else {
          replaceAll(context, const CustomerMainView());
        }
      } else {
        navigateTo(context, const LocationAccessView());
      }
    } catch (e) {
      if (!mounted) return;
      final rawMessage = e.toString();
      final cleanMessage = rawMessage.replaceFirst('Exception: ', '').trim();
      AppSnackbar.error(
        context,
        cleanMessage.isNotEmpty
            ? cleanMessage
            : 'Échec de la connexion. Vérifiez vos identifiants.',
      );
    }
  }

  @override
  void dispose() {
    if (_authVM.isLoading) {
      _authVM.cancelLogin();
    }
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Widget? _consumePendingPushScreen(currentUser) {
    if (currentUser == null) {
      return null;
    }

    final pendingData =
        PushNotificationService().takePendingNavigationPayload();
    if (pendingData == null) {
      return null;
    }

    final payload = PushNotificationPayload.fromData(pendingData);
    return _pushNavigationResolver.resolve(
      currentUser: currentUser,
      payload: payload,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final isLoading = authVM.isLoading;

    final isRestaurantManager =
        widget.selectedRole == UserRole.restaurantManager;
    final isDriver = widget.selectedRole == UserRole.driver;

    return AuthLayout(
      title:
          isRestaurantManager
              ? 'Espace Restaurant'
              : isDriver
              ? 'Connexion Livreur'
              : 'Connexion Client',
      subtitle: 'Veuillez vous connecter à votre compte',
      showBackButton: true,
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              PhoneField(controller: _phoneController, enabled: !isLoading),
              const SizedBox(height: 24),
              PinField(
                controller: _pinController,
                obscureText: _obscurePin,
                enabled: !isLoading,
                onToggleObscure:
                    () => setState(() => _obscurePin = !_obscurePin),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: AppTextButton(
            text: 'Code PIN oublié',
            fontWeight: FontWeight.normal,
            disabled: isLoading,
            onPressed: () {
              navigateTo(
                context,
                ForgotPinView(selectedRole: widget.selectedRole),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        AppButton(
          text: 'SE CONNECTER',
          isLoading: isLoading,
          onPressed: isLoading ? null : _login,
        ),
        const SizedBox(height: 24),
        if (isRestaurantManager) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                        children: [
                          const TextSpan(text: 'Bienvenue sur Dineroo ! '),
                          TextSpan(
                            text: 'Contactez-nous',
                            style: const TextStyle(
                              color: Colors.orange,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => launchUrl(
                                    Uri.parse('https://www.dineroo.africa/contact'),
                                    mode: LaunchMode.externalApplication,
                                  ),
                          ),
                          WidgetSpan(
                            child: Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.open_in_new, size: 14, color: Colors.orange),
                            ),
                            alignment: PlaceholderAlignment.middle,
                          ),
                          const TextSpan(
                              text: ' pour créer votre compte restaurant.'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (!isRestaurantManager)
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              const Text(
                'Pas encore inscrit ?',
                style: TextStyle(fontSize: 14),
              ),
              AppTextButton(
                text: 'Créer un compte',
                disabled: isLoading,
                onPressed: () {
                  navigateTo(
                    context,
                    SignUpView(selectedRole: widget.selectedRole),
                  );
                },
              ),
            ],
          ),
      ],
    );
  }
}
