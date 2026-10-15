import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_button.dart';

class ProfileLoadError extends StatelessWidget {
  final VoidCallback onRetry;

  const ProfileLoadError({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Impossible de charger votre profil.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Une erreur s\'est produite. Veuillez vous reconnecter pour continuer.',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(text: 'Se reconnecter', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
