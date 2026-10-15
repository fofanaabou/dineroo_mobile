import 'package:dineroo_mobile/shared/common/helpers/validators/form_validators.dart';
import 'package:dineroo_mobile/shared/common/helpers/phone_helper.dart';
import 'package:dineroo_mobile/shared/enums/user_role.dart';
import 'package:dineroo_mobile/shared/enums/verify_code_flow.dart';
import 'package:dineroo_mobile/shared/view_models/auth/auth_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/user_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:dineroo_mobile/driver/view_models/driver_home_view_model.dart';
import 'package:dineroo_mobile/shared/views/auth/login_view.dart';
import 'package:dineroo_mobile/shared/views/auth/verify_code_view.dart';
import 'package:dineroo_mobile/shared/views/auth/whoiam_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'sign_up_view.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_button.dart';
import '../../common/form_fields/phone_field.dart';
import '../../common/form_fields/pin_field.dart';
import 'auth_layout.dart';
import '../../common/helpers/navigation_helper.dart';
import '../../common/widgets/app_snackbar.dart';

class ForgotPinView extends StatefulWidget {
  final UserRole selectedRole;
  final bool isTemporaryPin;

  const ForgotPinView({
    super.key,
    required this.selectedRole,
    this.isTemporaryPin = false,
  });

  @override
  State<ForgotPinView> createState() => _ForgotPinViewState();
}

class _ForgotPinViewState extends State<ForgotPinView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;
  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final userVM = context.read<UserViewModel>();
    final currentUser = context.read<CurrentUserViewModel>().currentUser;

    final phone = formatPhoneGuinea(_phoneController.text);
    final codePin = _pinController.text.trim();

    try {
      String userId = currentUser?.id ?? '';
      if (userId.isEmpty) {
        final userData = await userVM.getUserByPhone(phone);
        userId = userData['id'] as String;
      }

      await userVM.sendVerificationCode(userId: userId, telephone: phone);
      if (!mounted) return;

      navigateTo(
        context,
        VerifyCodeView(
          flow: VerifyCodeFlow.resetPin,
          userData: {
            'telephone': phone,
            'codePin': codePin,
            'enabled': true,
            'role': widget.selectedRole.backendRole,
          },
          onSuccess: () async {
            final userRole = widget.selectedRole;
            final currentUser = context
                .read<CurrentUserViewModel>()
                .currentUser;
            if (currentUser != null) {
              if (currentUser.userRoleEnum == UserRole.driver) {
                await context
                    .read<DriverHomeViewModel>()
                    .resetDriverSessionServer();
              }
              await userVM.resetCodePinWithId(
                userId: currentUser.id,
                codePin: codePin,
              );
            } else {
              await userVM.resetCodePinWithPhone(
                telephone: phone,
                codePin: codePin,
              );
            }

            if (!mounted) return;
            await context.read<AuthViewModel>().logoutLocal(context);
            if (!mounted) return;
            replaceAll(context, const WhoiamView());
            navigateTo(context, LoginView(selectedRole: userRole));

            AppSnackbar.success(
              context,
              "Votre code PIN a été réinitialisé.",
              bottomMargin: 80,
            );
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(
        context,
        "Erreur lors de l'envoi du code de vérification.",
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRestaurantManager =
        widget.selectedRole == UserRole.restaurantManager;
    final currentUser = context.read<CurrentUserViewModel>().currentUser;

    return AuthLayout(
      title: (isRestaurantManager && widget.isTemporaryPin)
          ? 'Changer code PIN'
          : 'Code PIN oublié',
      subtitle: 'Veuillez saisir vos informations',
      showBackButton: true,
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              PhoneField(controller: _phoneController, enabled: !_isLoading),
              const SizedBox(height: 24),
              PinField(
                controller: _pinController,
                label: 'Nouveau code PIN',
                obscureText: _obscurePin,
                enabled: !_isLoading,
                onToggleObscure: () {
                  setState(() => _obscurePin = !_obscurePin);
                },
              ),
              const SizedBox(height: 24),
              PinField(
                controller: _confirmPinController,
                label: 'Confirmer le code PIN',
                obscureText: _obscureConfirmPin,
                enabled: !_isLoading,
                onToggleObscure: () {
                  setState(() => _obscureConfirmPin = !_obscureConfirmPin);
                },
                validator: (value) {
                  if (value != _pinController.text) {
                    return 'Les codes PIN ne correspondent pas.';
                  }
                  return FormValidators.validatePin(value);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AppButton(
          text: 'RÉINITIALISER',
          isLoading: _isLoading,
          onPressed: _isLoading ? null : _submit,
        ),
        const SizedBox(height: 24),
        if (!isRestaurantManager && currentUser == null)
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            children: [
              const Text(
                'Pas encore inscrit ?',
                style: TextStyle(fontSize: 14),
              ),
              AppTextButton(
                text: 'Créer un compte',
                disabled: _isLoading,
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
