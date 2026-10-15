import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextArea extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final int maxLength;
  final int maxLines;

  const AppTextArea({
    super.key,
    required this.controller,
    this.label = 'Commentaires (facultatif)',
    this.hintText = 'Écrivez ici…',
    this.maxLength = 1000,
    this.maxLines = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: const Color(0xFFF1F6FB),
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
