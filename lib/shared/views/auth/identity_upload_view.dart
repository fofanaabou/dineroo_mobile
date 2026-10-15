import 'dart:io';
import 'package:dineroo_mobile/shared/common/widgets/app_snackbar.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_button.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_file_picker.dart';
import 'package:dineroo_mobile/shared/enums/file_type.dart';
import 'package:dineroo_mobile/shared/view_models/auth/auth_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/user_view_model.dart';
import 'package:dineroo_mobile/shared/views/auth/thanks_sign_up_view.dart';
import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/common/helpers/navigation_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_scaffold.dart';
import 'package:provider/provider.dart';

class IdentityUploadView extends StatefulWidget {
  const IdentityUploadView({super.key});

  @override
  State<IdentityUploadView> createState() => _IdentityUploadViewState();
}

class _IdentityUploadViewState extends State<IdentityUploadView> {
  File? _selectedFile;
  late UserViewModel _userVM;

  @override
  void initState() {
    super.initState();
    _userVM = context.read<UserViewModel>();
  }

  @override
  void dispose() {
    if (_userVM.isLoading) {
      _userVM.cancelUploadUserFile();
    }
    super.dispose();
  }

  void _onFileSelected(File? file, String? name) {
    setState(() {
      _selectedFile = file;
    });
  }

  Future<void> _submit() async {
    if (_selectedFile == null) {
      AppSnackbar.error(context, "Veuillez ajouter une pièce d'identité.");
      return;
    }

    final currentUser = context.read<CurrentUserViewModel>().currentUser;
    if (currentUser == null) {
      AppSnackbar.error(context, "Une erreur est survenue.");
      return;
    }

    try {
      await _userVM.uploadUserFile(
        userId: currentUser.id,
        file: _selectedFile!,
        fileType: FileType.identityCard.value,
      );

      if (!mounted) return;
      await context.read<AuthViewModel>().updateCourierStatus('PENDING');

      if (!mounted) return;
      replaceWith(context, const ThanksForSignUpView());
    } catch (e) {
      AppSnackbar.error(
        context,
        e.toString().contains('timeout')
            ? "Temps d’attente dépassé. Réessayez."
            : "Échec de l'envoi de la pièce d'identité.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<UserViewModel>().isLoading;
    final screenHeight = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: false,
      child: AppScaffold(
        title: "Validation de l'identité",
        showCartIcon: false,
        body: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: screenHeight),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),
                    const Icon(
                      Icons.verified_user,
                      size: 80,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Ajoutez une pièce d'identité",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Cela nous permet de vérifier votre profil livreur.",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    AppFilePicker(
                      enabled: !isLoading,
                      onFileSelected: _onFileSelected,
                    ),
                    const SizedBox(height: 32),
                    AppButton(
                      text: 'SUIVANT',
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _submit,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
