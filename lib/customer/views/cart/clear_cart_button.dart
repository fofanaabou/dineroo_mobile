import 'package:dineroo_mobile/shared/common/widgets/app_text_button.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_dialog.dart';
import 'package:dineroo_mobile/customer/view_models/cart/cart_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ClearCartButton extends StatelessWidget {
  const ClearCartButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartViewModel>(
      builder: (context, cartVM, _) {
        if (cartVM.items.isEmpty) {
          return const SizedBox.shrink();
        }
        return AppTextButton(
          text: 'Vider',
          icon: Icons.delete_outline,
          color: Colors.redAccent,
          onPressed: () => _confirmClearCart(context),
        );
      },
    );
  }

  void _confirmClearCart(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AppDialog(
            title: 'Vider le panier',
            message:
                'Voulez-vous vraiment supprimer tous les articles de votre panier ?',
            confirmText: 'Vider',
            cancelText: 'Annuler',
            onConfirm: () {
              Provider.of<CartViewModel>(context, listen: false).clearCart();
              Navigator.of(context).pop();
            },
          ),
    );
  }
}
