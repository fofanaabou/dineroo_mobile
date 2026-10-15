import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/services/app_update/app_update_service.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_dialog.dart';

Future<void> showAppUpdateDialog(
  BuildContext context, {
  required AppUpdateResult result,
  required Future<void> Function() onUpdate,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: !result.forceUpdate,
    builder: (ctx) {
      return PopScope(
        canPop: !result.forceUpdate,
        child: AppDialog(
          title: 'Mise à jour disponible',
          message:
              '${result.message}\n\n'
              '${result.forceUpdate ? 'Cette mise à jour est obligatoire pour continuer.' : 'Vous pouvez mettre à jour maintenant ou plus tard.'}',
          confirmText: 'Mettre à jour',
          cancelText: 'Plus tard',
          showCancel: !result.forceUpdate,
          onCancel: () => Navigator.of(ctx).pop(),
          onConfirm: () async {
            if (!result.forceUpdate) Navigator.of(ctx).pop();
            await onUpdate();
          },
        ),
      );
    },
  );
}
