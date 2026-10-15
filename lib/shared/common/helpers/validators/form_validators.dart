import 'package:dineroo_mobile/shared/common/helpers/phone_helper.dart';

class FormValidators {
  static String? Function(String?) validateRequiredField(String fieldLabel) {
    return (value) {
      final trimmed = (value ?? '').trim();
      if (trimmed.isEmpty) {
        return 'Veuillez renseigner votre $fieldLabel.';
      }
      if (trimmed.length < 2) {
        return 'Le $fieldLabel doit contenir au moins 2 caractères.';
      }
      if (trimmed.length > 50) {
        return 'Le $fieldLabel ne doit pas dépasser 50 caractères.';
      }
      return null;
    };
  }

  static String? validatePhone(String? value) {
    if (!isValidGuineanPhone(value)) {
      return "Numéro invalide (ex: 6XX XX XX XX).";
    }
    return null;
  }

  static String? validatePin(String? value) {
    final digitsOnly = value?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (digitsOnly.length != 4) {
      return "Le code PIN doit contenir 4 chiffres.";
    }
    return null;
  }
}
