import 'package:dineroo_mobile/shared/common/widgets/app_avatar.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_call_button.dart';
import 'package:dineroo_mobile/shared/models/domain/contact.dart';
import 'package:flutter/material.dart';

class AppContactCard extends StatelessWidget {
  final Contact contact;
  final String? imageUrl;
  final Color backgroundColor;
  final Color textColor;
  final Color subtitleColor;
  final bool showCallButton;

  const AppContactCard({
    super.key,
    required this.contact,
    this.imageUrl,
    this.backgroundColor = const Color(0xFF1C1C1E),
    this.textColor = Colors.white,
    this.subtitleColor = Colors.white70,
    this.showCallButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: backgroundColor,
      ),
      child: Row(
        children: [
          AppAvatar(imageUrl: imageUrl, size: 48, showBorder: false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: textColor,
                  ),
                ),
                if (contact.subtitle != null &&
                    contact.subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    contact.subtitle!,
                    style: TextStyle(fontSize: 13, color: subtitleColor),
                  ),
                ],
              ],
            ),
          ),
          if (showCallButton) AppCallButton(phoneNumber: contact.phoneNumber),
        ],
      ),
    );
  }
}
