import 'package:flutter/material.dart';
import 'package:flutter_verification_code/flutter_verification_code.dart';

class AppVerifyCodeInput extends StatelessWidget {
  final void Function(String) onCompleted;
  final ValueChanged<bool>? onEditing;
  final String? errorMessage;
  final bool enabled;

  const AppVerifyCodeInput({
    super.key,
    required this.onCompleted,
    this.onEditing,
    this.errorMessage,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final available = width - 48; // 24px padding left/right in AuthLayout
    final boxSize = (available / 4) - 12; // 4 cases, 12px for margin
    final safeBoxSize = boxSize.clamp(40.0, 60.0);

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            VerificationCode(
              length: 4,
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              keyboardType: TextInputType.number,
              digitsOnly: true,
              underlineColor: Colors.transparent,
              fillColor: Colors.grey.shade200,
              itemSize: safeBoxSize,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              cursorColor: Colors.black,
              autofocus: true,
              onCompleted: onCompleted,
              onEditing: onEditing ?? (_) {},
            ),
            const SizedBox(height: 8),
            if (errorMessage != null)
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
