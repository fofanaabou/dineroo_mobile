import 'package:dineroo_mobile/shared/common/helpers/navigation_helper.dart';
import 'package:dineroo_mobile/shared/view_models/auth/auth_view_model.dart';
import 'package:dineroo_mobile/shared/views/auth/whoiam_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/widgets/app_button.dart';
import 'auth_layout.dart';

class ThanksForSignUpView extends StatelessWidget {
  const ThanksForSignUpView({super.key});

  void _redirectToWhoiam(BuildContext context) {
    final authVM = context.read<AuthViewModel>();
    authVM.logout(context);
    replaceAll(context, const WhoiamView());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _redirectToWhoiam(context);
        }
      },
      child: AuthLayout(
        subtitleWidget: Image.asset(
          'assets/images/app_cloche_icon.png',
          width: 150,
          height: 150,
        ),
        title: '',
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 15.0),
            child: SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Merci pour votre inscription !',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 60),
                Text(
                  'Votre compte est en cours de validation par notre équipe. Vous recevrez une notification dès qu’il sera validé.',
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 60),
          AppButton(text: 'OK', onPressed: () => _redirectToWhoiam(context)),
        ],
      ),
    );
  }
}
