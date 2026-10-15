import 'package:dineroo_mobile/shared/common/helpers/phone_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UserCallService {
  static Future<void> makeCall(BuildContext context, String phoneNumber) async {
    final normalizedPhone = normalizePhoneForCall(phoneNumber);

    if (normalizedPhone.isEmpty) {
      AppSnackbar.error(context, 'Numéro de téléphone non disponible');
      return;
    }

    final Uri url = Uri(scheme: 'tel', path: normalizedPhone);
    final canCall = await canLaunchUrl(url);

    if (canCall) {
      await launchUrl(url);
    } else {
      final displayPhone = formatPhoneDisplay(
        normalizedPhone,
        includeCountryCode: false,
      );

      if (!context.mounted) return;

      AppSnackbar.error(
        context,
        'Impossible d\'appeler ce numéro : $displayPhone',
      );
    }
  }
}
