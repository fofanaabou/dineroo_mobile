import 'package:dineroo_mobile/shared/common/widgets/app_icon.dart';
import 'package:flutter/material.dart';
import '../widgets/app_text_field.dart';
import '../helpers/validators/form_validators.dart';
import '../helpers/validators/form_formatters.dart';

class PinField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggleObscure;
  final bool enabled;
  final String? Function(String?)? validator;
  final String? label;

  const PinField({
    super.key,
    required this.controller,
    required this.obscureText,
    required this.onToggleObscure,
    this.enabled = true,
    this.validator,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label ?? 'Code PIN',
      hintText: '• • • •',
      controller: controller,
      obscureText: obscureText,
      keyboardType: TextInputType.number,
      inputFormatters: FormFormatters.pin4Digits,
      validator: validator ?? FormValidators.validatePin,
      suffixIcon: AppIcon(
        icon: obscureText ? Icons.visibility_off : Icons.visibility,
        onTap: onToggleObscure,
      ),
      enabled: enabled,
    );
  }
}
