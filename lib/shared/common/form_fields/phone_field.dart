import 'package:flutter/material.dart';
import '../widgets/app_text_field.dart';
import '../helpers/validators/form_validators.dart';
import '../helpers/validators/form_formatters.dart';

class PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const PhoneField({super.key, required this.controller, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: 'Téléphone',
      hintText: '6XX XX XX XX',
      controller: controller,
      keyboardType: TextInputType.phone,
      inputFormatters: FormFormatters.guineanPhone(),
      validator: FormValidators.validatePhone,
      enabled: enabled,
    );
  }
}
