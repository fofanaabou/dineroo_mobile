import 'package:dineroo_mobile/shared/common/utils/app_platform.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_dialog.dart';
import 'package:flutter/material.dart';

class LocationPermissionBlockedDialog extends StatelessWidget {
  static const String _deviceMessage =
      'Vous avez refusé l\'accès à votre position de manière permanente.\n\n'
      'Pour continuer, veuillez autoriser l\'accès à la localisation dans les paramètres de votre appareil.';
  static const String _browserMessage =
      'Vous avez bloqué l\'accès à votre position.\n\n'
      'Pour continuer, autorisez la localisation pour ce site dans les paramètres de votre navigateur '
      '(icône à gauche de l\'adresse), puis réessayez.';

  final VoidCallback onOpenSettings;

  const LocationPermissionBlockedDialog({
    super.key,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isWeb = AppPlatform.isWeb;

    return AppDialog(
      title: 'Autorisation requise',
      message: isWeb ? _browserMessage : _deviceMessage,
      confirmText: isWeb ? 'Compris' : 'Aller aux paramètres',
      showCancel: !isWeb,
      onConfirm: () {
        // A browser can't be sent to its own settings, so there is nothing to open there.
        if (!isWeb) onOpenSettings();
        Navigator.pop(context);
      },
      onCancel: () => Navigator.pop(context),
    );
  }
}
