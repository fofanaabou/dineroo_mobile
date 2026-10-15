import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class FormFormatters {
  /// Free text limited to 50 characters
  static List<TextInputFormatter> textMax50 = [
    LengthLimitingTextInputFormatter(50),
  ];

  /// Free text limited to 100 characters
  static List<TextInputFormatter> textMax100 = [
    LengthLimitingTextInputFormatter(100),
  ];

  /// Free text limited to 200 characters
  static List<TextInputFormatter> textMax200 = [
    LengthLimitingTextInputFormatter(200),
  ];

  /// Mask formatter for Guinean phone number: 6XX XX XX XX
  static final MaskTextInputFormatter guineanPhoneMask = MaskTextInputFormatter(
    mask: '### ## ## ##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  /// Input formatter list for Guinean phone
  static List<TextInputFormatter> guineanPhone() {
    return [guineanPhoneMask];
  }

  /// Formatter for 4-digit PIN: 0000
  static List<TextInputFormatter> pin4Digits = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(4),
  ];
}
