import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_dialog.dart';

class AddCatalogItemButton extends StatelessWidget {
  final bool isMenusTab;
  final VoidCallback? onTap;

  const AddCatalogItemButton({super.key, required this.isMenusTab, this.onTap});

  @override
  Widget build(BuildContext context) {
    final itemLabel = isMenusTab ? 'menu' : 'produit';
    final title = 'Ajouter un nouveau $itemLabel';
    final message = 'Merci de contacter le support pour ajouter un $itemLabel.';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap:
            onTap ??
            () => showDialog(
              context: context,
              builder: (_) => AppDialog(
                title: 'Ajouter un $itemLabel',
                message: message,
                confirmText: 'OK',
                showCancel: false,
              ),
            ),
        child: Container(
          width: double.infinity,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FB),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.orange, width: 2),
                ),
                child: const Icon(Icons.add, color: Colors.orange, size: 18),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
