import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_icon.dart';

class AppSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final int maxLength;

  const AppSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Rechercher...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.maxLength = 50,
  });

  bool get _showClearIcon => controller.text.trim().isNotEmpty;

  void _handleInput(String value, ValueChanged<String>? callback) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      callback?.call(trimmed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFF2F2F1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLength: maxLength,
        maxLengthEnforcement: MaxLengthEnforcement.enforced,
        buildCounter:
            (
              _, {
              required currentLength,
              required isFocused,
              required maxLength,
            }) => null,
        onChanged: (value) => _handleInput(value, onChanged),
        onSubmitted: (value) => _handleInput(value, onSubmitted),
        style: const TextStyle(fontSize: 16, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.black54),
          prefixIcon: const Icon(Icons.search, color: Colors.black54),
          suffixIcon:
              _showClearIcon
                  ? AppIcon(
                    icon: Icons.close,
                    color: Colors.black54,
                    onTap: () {
                      controller.clear();
                      onClear?.call();
                    },
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
