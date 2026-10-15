import 'package:dineroo_mobile/shared/common/widgets/app_contact_card.dart';
import 'package:dineroo_mobile/shared/models/domain/contact.dart';
import 'package:flutter/material.dart';

class TrackingCardStepsStep extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool showConnector;
  final double connectorHeight;
  final Contact? contact;
  final bool isDisabled;

  const TrackingCardStepsStep({
    super.key,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.showConnector = true,
    this.connectorHeight = 30,
    this.contact,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDisabled ? Colors.black38 : Colors.black;
    final subtitleColor = isDisabled ? Colors.black26 : Colors.black54;
    final iconBgColor = isDisabled ? const Color(0xFFF3F3F3) : backgroundColor;
    final iconColorActual = isDisabled ? Colors.grey : iconColor;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBgColor,
              ),
              child: Center(
                child: Icon(icon, size: 18, color: iconColorActual),
              ),
            ),
            if (showConnector)
              Container(
                width: 2,
                height: connectorHeight,
                color: const Color(0xFFE0E0E0),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: subtitleColor),
              ),
              if (contact != null)
                AppContactCard(
                  contact: contact!,
                  backgroundColor: Colors.transparent,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
