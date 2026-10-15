import 'package:dineroo_mobile/shared/common/constants/constants.dart';
import 'package:dineroo_mobile/shared/common/helpers/validators/form_formatters.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

/// Extract 9 digits from Guinean number
/// (eg: +2246XXXXXXXX / 2246XXXXXXXX / 6XXXXXXXX → 6XXXXXXXX)
String toGuinean9Digits(String? input) {
  final digits = (input ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';
  return digits.length >= 9 ? digits.substring(digits.length - 9) : digits;
}

/// Validate Guinean phone number
/// (must be 9 digits starting with 6, 7 or 8)
bool isValidGuineanPhone(String? input) {
  final local = toGuinean9Digits(input);
  return RegExp(r'^[678]\d{8}$').hasMatch(local);
}

/// Normalize phone number for call (tel:)
/// (return 9 digits or empty string if invalid)
String normalizePhoneForCall(String? input) {
  final local = toGuinean9Digits(input);
  return isValidGuineanPhone(local) ? local : '';
}

/// Format Guinean number for display
/// (eg: +2246XXXXXXXX → +224 6XX XX XX XX)
/// Param [includeCountryCode] to include or not the country code (+224)
String formatPhoneDisplay(String? input, {bool includeCountryCode = true}) {
  final local = toGuinean9Digits(input);

  if (!isValidGuineanPhone(local)) {
    return input?.trim() ?? '';
  }

  final formatted =
      FormFormatters.guineanPhoneMask
          .formatEditUpdate(
            const TextEditingValue(),
            TextEditingValue(text: local),
          )
          .text;

  return includeCountryCode
      ? '${Constants.guineaCountryCode} $formatted'
      : formatted;
}

/// Format Guinean number for API
/// (eg: 6XXXXXXXX → +2246XXXXXXXX)
String formatPhoneGuinea(String rawPhone) {
  final formatter = MaskTextInputFormatter(
    mask: '### ## ## ##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  formatter.formatEditUpdate(
    const TextEditingValue(),
    TextEditingValue(text: rawPhone),
  );

  final cleaned = formatter.getUnmaskedText();
  return '${Constants.guineaCountryCode}$cleaned';
}

/// Format phone for input field
/// (eg: +2246XXXXXXXX → 6XX XX XX XX)
String formatPhoneInput(String? input) {
  final local = toGuinean9Digits(input);

  if (local.isEmpty) return '';

  return FormFormatters.guineanPhoneMask
      .formatEditUpdate(const TextEditingValue(), TextEditingValue(text: local))
      .text;
}
