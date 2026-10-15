import 'package:dineroo_mobile/customer/models/domain/delivery_address.dart';
import 'package:dineroo_mobile/customer/view_models/cart/cart_view_model.dart';
import 'package:dineroo_mobile/shared/common/helpers/validators/form_formatters.dart';
import 'package:dineroo_mobile/shared/common/helpers/phone_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_button.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dineroo_mobile/shared/common/form_fields/phone_field.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_text_field.dart';
import 'package:dineroo_mobile/shared/common/helpers/validators/form_validators.dart';

class DeliveryContactFormSheet extends StatefulWidget {
  final String title;
  final String submitLabel;

  const DeliveryContactFormSheet({
    super.key,
    this.title = 'Informations de livraison',
    this.submitLabel = 'Enregistrer',
  });

  static Future<bool?> open(
    BuildContext context, {
    String title = 'Informations de livraison',
    String submitLabel = 'Enregistrer',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          DeliveryContactFormSheet(title: title, submitLabel: submitLabel),
    );
  }

  @override
  State<DeliveryContactFormSheet> createState() =>
      _DeliveryContactFormSheetState();
}

class _DeliveryContactFormSheetState extends State<DeliveryContactFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _districtCtrl;
  late final TextEditingController _communeCtrl;
  late final TextEditingController _instructionsCtrl;

  @override
  void initState() {
    super.initState();

    final cart = context.read<CartViewModel>();
    final currentUser = context.read<CurrentUserViewModel>().currentUser;

    final rawPhone =
        (cart.deliveryPhoneNumber ?? currentUser?.phoneNumber ?? '').trim();

    _firstNameCtrl = TextEditingController(
      text: (cart.deliveryFirstName ?? currentUser?.firstName ?? '').trim(),
    );

    _lastNameCtrl = TextEditingController(
      text: (cart.deliveryLastName ?? currentUser?.lastName ?? '').trim(),
    );

    _phoneCtrl = TextEditingController(text: formatPhoneInput(rawPhone));

    _addressCtrl = TextEditingController(
      text: (cart.deliveryAddress ?? '').trim(),
    );
    _districtCtrl = TextEditingController(
      text: (cart.deliveryDistrict ?? '').trim(),
    );
    _communeCtrl = TextEditingController(
      text: (cart.deliveryCommune ?? '').trim(),
    );
    _instructionsCtrl = TextEditingController(
      text: (cart.deliveryInstructions ?? '').trim(),
    );
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _districtCtrl.dispose();
    _communeCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final cart = context.read<CartViewModel>();

    if (!_formKey.currentState!.validate()) return;

    final delivery = DeliveryAddress(
      firstName: _firstNameCtrl.text.trim().isEmpty
          ? null
          : _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim().isEmpty
          ? null
          : _lastNameCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      district: _districtCtrl.text.trim(),
      commune: _communeCtrl.text.trim().isEmpty
          ? null
          : _communeCtrl.text.trim(),
      instructions: _instructionsCtrl.text.trim().isEmpty
          ? null
          : _instructionsCtrl.text.trim(),
    );

    cart.setDeliveryContact(delivery);

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFEAEAEA))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'Fermer',
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppTextField(
                      label: 'Prénom',
                      hintText: 'Ex: Mamadou',
                      controller: _firstNameCtrl,
                      textInputAction: TextInputAction.next,
                      validator: FormValidators.validateRequiredField('prénom'),
                      inputFormatters: FormFormatters.textMax50,
                    ),
                    const SizedBox(height: 20),

                    AppTextField(
                      label: 'Nom (optionnel)',
                      hintText: 'Ex: Diallo',
                      controller: _lastNameCtrl,
                      textInputAction: TextInputAction.next,
                      inputFormatters: FormFormatters.textMax50,
                    ),
                    const SizedBox(height: 20),

                    PhoneField(controller: _phoneCtrl),
                    const SizedBox(height: 20),

                    AppTextField(
                      label: 'Adresse',
                      hintText: 'Ex: 12 Avenue de la République',
                      controller: _addressCtrl,
                      keyboardType: TextInputType.streetAddress,
                      textInputAction: TextInputAction.next,
                      validator: FormValidators.validateRequiredField(
                        'adresse',
                      ),
                      inputFormatters: FormFormatters.textMax100,
                    ),
                    const SizedBox(height: 20),

                    AppTextField(
                      label: 'Quartier',
                      hintText: 'Ex: Nongo, Kipé, Lambanyi...',
                      controller: _districtCtrl,
                      textInputAction: TextInputAction.next,
                      validator: FormValidators.validateRequiredField(
                        'quartier',
                      ),
                      inputFormatters: FormFormatters.textMax50,
                    ),
                    const SizedBox(height: 20),

                    AppTextField(
                      label: 'Commune (optionnel)',
                      hintText: 'Ex: Ratoma, Matoto...',
                      controller: _communeCtrl,
                      textInputAction: TextInputAction.next,
                      inputFormatters: FormFormatters.textMax50,
                    ),
                    const SizedBox(height: 20),

                    AppTextField(
                      label: 'Autres informations (optionnel)',
                      hintText: 'Ex: près de la pharmacie, portail bleu…',
                      controller: _instructionsCtrl,
                      maxLines: 2,
                      inputFormatters: FormFormatters.textMax200,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEAEAEA))),
            ),
            child: SafeArea(
              top: false,
              child: AppButton(text: widget.submitLabel, onPressed: _save),
            ),
          ),
        ],
      ),
    );
  }
}
