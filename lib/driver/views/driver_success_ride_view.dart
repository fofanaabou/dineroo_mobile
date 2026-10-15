import 'package:dineroo_mobile/driver/view_models/driver_home_view_model.dart';
import 'package:dineroo_mobile/driver/views/driver_main_view.dart';
import 'package:dineroo_mobile/shared/common/helpers/navigation_helper.dart';
import 'package:dineroo_mobile/shared/common/helpers/price_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_button.dart';
import 'package:provider/provider.dart';

class DriverSuccessRideView extends StatelessWidget {
  final num deliveryFee;

  const DriverSuccessRideView({super.key, required this.deliveryFee});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 100,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Bravo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A0338),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Vous avez terminé la course. Montant ajouté à vos gains :',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    formatPrice(deliveryFee),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16),
          child: AppButton(
            text: "D'ACCORD",
            backgroundColor: const Color(0xFFFF6600),
            onPressed: () async {
              final vm = Provider.of<DriverHomeViewModel>(
                context,
                listen: false,
              );

              try {
                await vm.completeRide();
                await vm.goOnline();
              } catch (_) {
                if (!context.mounted) return;
                AppSnackbar.error(
                  context,
                  vm.error ?? 'Impossible de finaliser la livraison.',
                );
                return;
              }

              if (!context.mounted) return;
              replaceAll(context, const DriverMainView());
            },
          ),
        ),
      ),
    );
  }
}
