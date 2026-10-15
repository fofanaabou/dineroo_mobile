import 'dart:io';
import 'package:dineroo_mobile/shared/common/helpers/phone_helper.dart';
import 'package:dineroo_mobile/shared/enums/verify_code_flow.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:dineroo_mobile/shared/views/profile/profile_load_error.dart';
import 'package:dineroo_mobile/shared/views/profile/profile_content.dart';
import 'package:dineroo_mobile/shared/common/helpers/safe_context_helper.dart';
import 'package:dineroo_mobile/shared/view_models/auth/auth_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/user_view_model.dart';
import 'package:dineroo_mobile/shared/views/auth/whoiam_view.dart';
import 'package:dineroo_mobile/shared/common/helpers/navigation_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_snackbar.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_text_button.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_button.dart';
import 'package:dineroo_mobile/shared/common/helpers/user_role_helper.dart';
import 'package:dineroo_mobile/shared/views/auth/forgot_pin_view.dart';
import 'package:dineroo_mobile/shared/common/constants/constants.dart';
import 'package:dineroo_mobile/shared/views/auth/verify_code_view.dart';

class ProfileView extends StatefulWidget {
  final List<Widget> actionTiles;

  const ProfileView({super.key, this.actionTiles = const []});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  File? _profileImage;
  bool _isEditing = false;
  bool _isLoggingOut = false;
  User? _cachedUser;

  @override
  void initState() {
    super.initState();
    _isEditing = false;
    final currentUser = context.read<CurrentUserViewModel>().currentUser;
    if (currentUser != null) {
      _populateFieldsFromUser(currentUser);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.watch<CurrentUserViewModel>().currentUser;
    if (user != null && user != _cachedUser) {
      _populateFieldsFromUser(user);
      _isEditing = false;
    }
  }

  void _populateFieldsFromUser(User user) {
    _cachedUser = user;
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _phoneController.text = formatPhoneInput(user.phoneNumber);
  }

  void _toggleEdit() {
    if (_isEditing) {
      setState(() => _isEditing = false);
    } else {
      _enableEditModeWithFormattedPhone();
    }
  }

  void _enableEditModeWithFormattedPhone() {
    _phoneController.text = formatPhoneInput(_phoneController.text);
    setState(() => _isEditing = true);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_hasProfileChanged()) {
      setState(() => _isEditing = false);
      return;
    }

    final currentUser = context.read<CurrentUserViewModel>().currentUser;
    if (currentUser == null) return;

    final userVM = context.read<UserViewModel>();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final formattedPhone = formatPhoneGuinea(_phoneController.text);

    final hasPhoneChanged = formattedPhone != currentUser.phoneNumber;

    try {
      if (hasPhoneChanged) {
        await userVM.sendVerificationCode(
          userId: currentUser.id,
          telephone: formattedPhone,
        );
        if (!mounted) return;

        navigateTo(
          context,
          VerifyCodeView(
            flow: VerifyCodeFlow.changePhone,
            newPhoneNumber: formattedPhone,
            onSuccess: () async {
              await _updateProfile(
                userId: currentUser.id,
                firstName: firstName,
                lastName: lastName,
                phoneNumber: formattedPhone,
              );
              if (!mounted) return;
              Navigator.of(context).pop();
            },
          ),
        );
        return;
      }

      await _updateProfile(
        userId: currentUser.id,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: formattedPhone,
      );
      if (!mounted) return;

      setState(() => _isEditing = false);
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error(
        context,
        'Une erreur est survenue lors de la mise à jour.',
        bottomMargin: 80,
      );
    }
  }

  Future<void> _updateProfile({
    required String userId,
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    final userVM = context.read<UserViewModel>();
    final currentUser = context.read<CurrentUserViewModel>().currentUser;

    await userVM.updateUser(
      userId: userId,
      firstName: firstName,
      lastName: lastName,
      telephone: phoneNumber,
    );
    if (!mounted) return;

    context.read<CurrentUserViewModel>().setUser(
      currentUser!.copyWith(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      ),
    );

    AppSnackbar.success(
      context,
      'Profil mis à jour avec succès.',
      bottomMargin: 80,
    );
  }

  bool _hasProfileChanged() {
    final currentFirstName = _firstNameController.text.trim();
    final currentLastName = _lastNameController.text.trim();
    final currentPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final originalPhone = _cachedUser!.phoneNumber.replaceAll(
      Constants.guineaCountryCode,
      '',
    );
    return currentFirstName != _cachedUser!.firstName ||
        currentLastName != _cachedUser!.lastName ||
        currentPhone != originalPhone;
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    await safeCallWithContext(
      state: this,
      asyncOperation: () => context.read<AuthViewModel>().logout(context),
      onSuccess: (ctx) => replaceAll(ctx, const WhoiamView()),
      onError:
          (ctx) => AppSnackbar.error(
            ctx,
            'Échec de la déconnexion',
            bottomMargin: 80,
          ),
      onComplete: (ctx) => setState(() => _isLoggingOut = false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userVM = context.watch<UserViewModel>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child:
                _isLoggingOut
                    ? const AppLoader(size: 28, strokeWidth: 2.2)
                    : AppTextButton(
                      text: 'Déconnexion',
                      onPressed: _logout,
                      fontWeight: FontWeight.w600,
                    ),
          ),
        ],
      ),
      body: SafeArea(
        child:
            _isLoggingOut
                ? const Center(child: AppLoader())
                : _cachedUser == null
                ? ProfileLoadError(onRetry: _logout)
                : Form(
                  key: _formKey,
                  child: ProfileContent(
                    user: _cachedUser!,
                    profileImage: _profileImage,
                    isEditing: _isEditing,
                    firstNameController: _firstNameController,
                    lastNameController: _lastNameController,
                    phoneController: _phoneController,
                    actionTiles: widget.actionTiles,
                    onToggleObscure: () {
                      final roleEnum = parseUserRole(_cachedUser!.role);
                      navigateTo(
                        context,
                        ForgotPinView(selectedRole: roleEnum),
                      );
                    },
                  ),
                ),
      ),
      bottomNavigationBar:
          (!_isLoggingOut && _cachedUser != null)
              ? Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: AppButton(
                  text: _isEditing ? 'ENREGISTRER' : 'MODIFIER',
                  onPressed:
                      _isEditing && userVM.isLoading
                          ? null
                          : (_isEditing ? _saveProfile : _toggleEdit),
                  isLoading: _isEditing && userVM.isLoading,
                ),
              )
              : null,
    );
  }
}
