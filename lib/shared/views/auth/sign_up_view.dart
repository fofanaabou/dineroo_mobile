import 'package:dineroo_mobile/shared/common/helpers/phone_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_text_button.dart';
import 'package:dineroo_mobile/shared/common/form_fields/first_name_field.dart';
import 'package:dineroo_mobile/shared/common/form_fields/last_name_field.dart';
import 'package:dineroo_mobile/shared/common/form_fields/phone_field.dart';
import 'package:dineroo_mobile/shared/common/form_fields/pin_field.dart';
import 'package:dineroo_mobile/shared/enums/user_role.dart';
import 'package:dineroo_mobile/shared/enums/verify_code_flow.dart';
import 'package:dineroo_mobile/shared/view_models/user/user_view_model.dart';
import 'package:dineroo_mobile/shared/views/auth/login_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'verify_code_view.dart';
import '../../common/widgets/app_button.dart';
import 'auth_layout.dart';
import '../../common/helpers/navigation_helper.dart';
import '../../common/widgets/app_snackbar.dart';

class SignUpView extends StatefulWidget {
  final UserRole selectedRole;

  const SignUpView({super.key, required this.selectedRole});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  bool _obscurePin = true;

  late UserViewModel _userVM;

  @override
  void initState() {
    super.initState();
    _userVM = Provider.of<UserViewModel>(context, listen: false);
  }

  @override
  void dispose() {
    if (_userVM.isLoading) {
      _userVM.cancelCreateUser();
    }
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _submit() async {
    final isRestaurantManager =
        widget.selectedRole == UserRole.restaurantManager;
    if (isRestaurantManager) {
      AppSnackbar.warning(
        context,
        "Contactez Dineroo pour créer un compte restaurant.",
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final userData = {
      'telephone': formatPhoneGuinea(_phoneController.text),
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'enabled': true,
      'codePin': _pinController.text,
      'role': widget.selectedRole.backendRole,
    };

    try {
      await _userVM.createUser(userData);
      if (!mounted) return;

      navigateTo(
        context,
        VerifyCodeView(userData: userData, flow: VerifyCodeFlow.signUp),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Échec de la création du compte.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<UserViewModel>().isLoading;

    return AuthLayout(
      title: 'Créer un compte',
      subtitle: 'Veuillez renseigner vos informations',
      showBackButton: true,
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              FirstNameField(
                controller: _firstNameController,
                enabled: !isLoading,
              ),
              const SizedBox(height: 24),
              LastNameField(
                controller: _lastNameController,
                enabled: !isLoading,
              ),
              const SizedBox(height: 24),
              PhoneField(controller: _phoneController, enabled: !isLoading),
              const SizedBox(height: 24),
              PinField(
                controller: _pinController,
                obscureText: _obscurePin,
                enabled: !isLoading,
                onToggleObscure:
                    () => setState(() => _obscurePin = !_obscurePin),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        AppButton(
          text: 'SUIVANT',
          isLoading: isLoading,
          onPressed: isLoading ? null : _submit,
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          children: [
            const Text(
              'Vous avez déjà un compte ?',
              style: TextStyle(fontSize: 14),
            ),
            AppTextButton(
              text: 'Se connecter',
              disabled: isLoading,
              onPressed: () {
                navigateTo(
                  context,
                  LoginView(selectedRole: widget.selectedRole),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
