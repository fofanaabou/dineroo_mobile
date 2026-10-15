import 'package:dineroo_mobile/customer/view_models/cart/cart_view_model.dart';
import 'package:dineroo_mobile/customer/views/cart/delivery_contact_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DeliveryInfoSection extends StatelessWidget {
  const DeliveryInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartViewModel>();
    final label = (cart.deliveryLabel ?? '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LIVRER À',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.deepOrange,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),

        Material(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => DeliveryContactFormSheet.open(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Colors.deepOrange,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label.isEmpty
                          ? 'Ajouter une adresse de livraison'
                          : label,
                      style: TextStyle(
                        fontSize: 14,
                        color: label.isEmpty ? Colors.black54 : Colors.black87,
                        fontWeight:
                            label.isEmpty ? FontWeight.w400 : FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),

                  SizedBox(
                    width: 40,
                    height: 30,
                    child: Center(
                      child:
                          label.isNotEmpty
                              ? InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap:
                                    () =>
                                        context
                                            .read<CartViewModel>()
                                            .clearDeliveryAddress(),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.redAccent,
                                  size: 22,
                                ),
                              )
                              : const Icon(
                                Icons.chevron_right,
                                color: Colors.black45,
                                size: 24,
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
