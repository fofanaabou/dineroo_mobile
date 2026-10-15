import 'package:dineroo_mobile/shared/common/helpers/phone_helper.dart';
import 'package:dineroo_mobile/shared/enums/verify_code_flow.dart';
import 'package:dineroo_mobile/shared/view_models/auth/auth_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/user_role_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/user_view_model.dart';
import 'package:dineroo_mobile/shared/views/auth/identity_upload_view.dart';
import 'package:dineroo_mobile/shared/views/location/location_access_view.dart';
import 'package:dineroo_mobile/shared/common/helpers/navigation_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_button.dart';
import '../../common/widgets/app_verify_code_input.dart';
import 'auth_layout.dart';

class VerifyCodeView extends StatefulWidget {
  final VerifyCodeFlow flow;
  final String? newPhoneNumber;
  final Map<String, dynamic>? userData;
  final Future<void> Function()? onSuccess;

  const VerifyCodeView({
    super.key,
    required this.flow,
    this.newPhoneNumber,
    this.userData,
    this.onSuccess,
  });

  @override
  State<VerifyCodeView> createState() => _VerifyCodeViewState();
}

class _VerifyCodeViewState extends State<VerifyCodeView> {
  static const int _initialResendDelay = 30;
  int _resendSeconds = _initialResendDelay;
  String _enteredCode = '';
  String? _errorMessage;
  bool _isVerifying = false;

  late AuthViewModel _authVM;
  late final String _displayedPhoneNumber;

  @override
  void initState() {
    super.initState();

    if (widget.flow == VerifyCodeFlow.changePhone) {
      _displayedPhoneNumber = widget.newPhoneNumber!;
    } else {
      _displayedPhoneNumber = widget.userData?['telephone'] ?? '';
    }

    _authVM = context.read<AuthViewModel>();
    _decrementTimer();
  }

  @override
  void dispose() {
    if (_authVM.isLoading) {
      _authVM.cancelVerifyCode();
    }
    super.dispose();
  }

  void _decrementTimer() {
    if (_resendSeconds > 0) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() => _resendSeconds--);
          _decrementTimer();
        }
      });
    }
  }

  Future<void> _onResendCode() async {
    final userVM = context.read<UserViewModel>();
    final currentUser = context.read<CurrentUserViewModel>().currentUser;

    try {
      switch (widget.flow) {
        case VerifyCodeFlow.changePhone:
          await userVM.sendVerificationCode(
            userId: currentUser!.id,
            telephone: widget.newPhoneNumber!,
          );
          break;

        case VerifyCodeFlow.resetPin:
          String userId = currentUser?.id ?? '';
          final telephone = widget.userData!['telephone'] as String;

          if (userId.isEmpty) {
            final u = await userVM.getUserByPhone(telephone);
            userId = u['id'] as String;
          }
          await userVM.sendVerificationCode(
            userId: userId,
            telephone: telephone,
          );
          break;

        case VerifyCodeFlow.signUp:
          if (widget.userData != null) {
            await userVM.createUser(widget.userData!);
          } else {
            throw Exception('Missing userData to continue');
          }
          break;
      }

      if (!mounted) return;
      AppSnackbar.success(context, 'Nouveau code envoyé.');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Erreur lors de la régénération du code.');
    }

    setState(() {
      _resendSeconds = _initialResendDelay;
      _errorMessage = null;
    });
    _decrementTimer();
  }

  Future<void> _verifyCode() async {
    if (_isVerifying) return;

    final code = _enteredCode.trim();
    if (code.length != 4) {
      setState(() => _errorMessage = 'Veuillez saisir les 4 chiffres du code.');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final userVM = context.read<UserViewModel>();
      final roleVM = context.read<UserRoleViewModel>();
      final currentUser = context.read<CurrentUserViewModel>().currentUser;

      switch (widget.flow) {
        case VerifyCodeFlow.changePhone:
          await userVM.validateCode(
            userId: currentUser!.id,
            code: code,
          );
          await widget.onSuccess?.call();
          return;

        case VerifyCodeFlow.resetPin:
          String userId = currentUser?.id ?? '';
          if (userId.isEmpty) {
            final u = await userVM.getUserByPhone(_displayedPhoneNumber);
            userId = u['id'] as String;
          }
          await userVM.validateCode(userId: userId, code: code);
          await widget.onSuccess?.call();
          return;

        case VerifyCodeFlow.signUp:
          await _authVM.verifyCode(code, context: context);
          if (!mounted) return;

          if (roleVM.isGuest) {
            navigateTo(context, const IdentityUploadView());
          } else if (roleVM.isCustomer) {
            replaceWith(context, const LocationAccessView());
          } else {
            AppSnackbar.error(context, 'Rôle utilisateur non reconnu.');
          }
          return;
      }
    } catch (e) {
      if (!mounted) return;
      final message = e.toString();
      final userMessage =
          message.contains('Code invalide ou expire') ||
                  message.contains('Code invalide ou expiré')
              ? 'Code invalide ou expiré. Demandez un nouveau code.'
              : message.contains('a deja un compte') ||
                  message.contains('a déjà un compte') ||
                  message.contains('User exists with same username')
              ? 'Ce numéro a déjà un compte. Connectez-vous ou réinitialisez votre code PIN.'
              : message.contains('Account disabled')
              ? 'Ce compte est désactivé. Utilisez un autre numéro ou contactez le support.'
              : 'Code incorrect. Veuillez réessayer.';
      setState(() => _errorMessage = userMessage);
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        widget.flow == VerifyCodeFlow.changePhone
            ? context.watch<UserViewModel>().isLoading
            : context.watch<AuthViewModel>().isLoading;

    return AuthLayout(
      title: 'Vérification',
      subtitleWidget: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(fontSize: 16, color: Colors.white70),
          children: [
            const TextSpan(text: 'Un code a été envoyé à\n'),
            TextSpan(
              text: formatPhoneDisplay(_displayedPhoneNumber),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      showBackButton: true,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('CODE', style: TextStyle(fontSize: 14)),
            AppTextButton(
              text:
                  _resendSeconds == 0
                      ? 'Renvoyer'
                      : 'Renvoyer dans ${_resendSeconds}s',
              color:
                  _resendSeconds == 0 ? const Color(0xFF0F0F2D) : Colors.grey,
              fontSize: 14,
              disabled: _resendSeconds != 0 || isLoading || _isVerifying,
              onPressed: _resendSeconds == 0 ? _onResendCode : () {},
            ),
          ],
        ),
        const SizedBox(height: 8),
        AppVerifyCodeInput(
          enabled: !isLoading && !_isVerifying,
          errorMessage: _errorMessage,
          onEditing: (isEditing) {
            if (!isEditing) return;
            setState(() {
              _enteredCode = '';
              _errorMessage = null;
            });
          },
          onCompleted: (value) {
            setState(() => _enteredCode = value);
            _verifyCode();
          },
        ),
        const SizedBox(height: 24),
        AppButton(
          text: 'VÉRIFIER',
          onPressed:
              (isLoading || _isVerifying || _enteredCode.trim().length != 4)
                  ? null
                  : _verifyCode,
          isLoading: isLoading || _isVerifying,
        ),
      ],
    );
  }
}
