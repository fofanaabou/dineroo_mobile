import 'package:flutter/material.dart';
import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:dineroo_mobile/shared/common/helpers/navigation_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_snackbar.dart';
import 'package:dineroo_mobile/shared/view_models/auth/auth_view_model.dart';
import 'package:dineroo_mobile/shared/views/auth/identity_upload_view.dart';

Future<bool> handleDriverAccountAccess(
  BuildContext context,
  AuthViewModel authVM,
  User? user,
) async {
  if (user?.isMissingCourierFile == true) {
    replaceWith(context, const IdentityUploadView());
    return true;
  }

  await showDriverAccountAccessWarning(context, authVM, user);
  return false;
}

Future<void> showDriverAccountAccessWarning(
  BuildContext context,
  AuthViewModel authVM,
  User? user,
) async {
  var message = 'Votre compte est en attente de validation.';
  if (user?.isRejectedCourier == true) {
    message = 'Votre compte a été refusé. Veuillez contacter le support.';
  }
  AppSnackbar.warning(context, message);
  await authVM.logout(context);
}
