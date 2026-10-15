import 'package:flutter/material.dart';
import '../widgets/app_text_field.dart';
import '../helpers/validators/form_validators.dart';
import '../helpers/validators/form_formatters.dart';

class LastNameField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const LastNameField({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: 'Nom',
      hintText: 'Diallo',
      controller: controller,
      keyboardType: TextInputType.name,
      inputFormatters: FormFormatters.textMax50,
      validator: FormValidators.validateRequiredField('nom'),
      enabled: enabled,
    );
  }
}
