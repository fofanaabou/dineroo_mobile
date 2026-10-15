import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_button.dart';

class AppSuccessView extends StatelessWidget {
  const AppSuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/app_withdraw.png',
                width: isPortrait ? 350 : 250,
                height: isPortrait ? 350 : 250,
                fit: BoxFit.contain,
              ),
              SizedBox(height: isPortrait ? 24 : 16),
              const Text(
                'Retrait effectué avec succès !',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: isPortrait ? 24 : 16),
              AppButton(
                text: 'OK',
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
