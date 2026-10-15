import 'package:dineroo_mobile/shared/common/helpers/opening_hours_helper.dart';
import 'package:dineroo_mobile/shared/models/domain/opening_hours.dart';
import 'package:flutter/material.dart';

class RestaurantOpenStatusBadge extends StatelessWidget {
  final List<OpeningHours> openingHours;
  final bool showNextOpening;
  static const Duration _opensSoonThreshold = Duration(hours: 1);

  const RestaurantOpenStatusBadge({
    super.key,
    required this.openingHours,
    this.showNextOpening = true,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = OpeningHoursHelper.restaurantIsOpen(openingHours);
    final nextOpeningHour = OpeningHoursHelper.nextOpeningHour(openingHours);
    final opensSoon = OpeningHoursHelper.restaurantOpensWithin(
      openingHours,
      _opensSoonThreshold,
    );

    String statusLabel;
    Color statusColor;

    if (isOpen) {
      statusLabel = 'Restaurant ouvert';
      statusColor = Colors.green;
    } else if (showNextOpening && nextOpeningHour != null && opensSoon) {
      statusLabel = 'Restaurant fermé - ouvre à $nextOpeningHour';
      statusColor = Colors.orange;
    } else {
      statusLabel = 'Restaurant fermé';
      statusColor = Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusLabel,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: statusColor,
        ),
      ),
    );
  }
}
