import 'package:dineroo_mobile/manager/views/manager_suspension_notice.dart';
import 'package:dineroo_mobile/shared/common/helpers/opening_hours_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:dineroo_mobile/shared/common/widgets/restaurant_open_status_badge.dart';
import 'package:dineroo_mobile/shared/models/domain/opening_hours.dart';
import 'package:flutter/material.dart';

class ManagerHomeStatusHeader extends StatelessWidget {
  static const Color _accent = Color(0xFFFF4B12);
  static const Color _disabledAccent = Color(0xFF8A8A8E);

  final List<OpeningHours> openingHours;
  final bool isLoading;
  final bool isSuspended;
  final VoidCallback onTap;

  const ManagerHomeStatusHeader({
    super.key,
    required this.openingHours,
    required this.isLoading,
    required this.onTap,
    this.isSuspended = false,
  });

  @override
  Widget build(BuildContext context) {
    final todayRanges = OpeningHoursHelper.currentDayRanges(openingHours);
    final isOpen = OpeningHoursHelper.restaurantIsOpen(openingHours);
    final nextOpeningLabel = OpeningHoursHelper.nextOpeningLabel(openingHours);
    final todayLabel = isOpen
        ? OpeningHoursHelper.formatRanges(todayRanges)
        : nextOpeningLabel ?? 'Horaires indisponibles';
    final showInitialLoading = isLoading && openingHours.isEmpty;

    final accent = isSuspended ? _disabledAccent : _accent;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: isSuspended
            ? () => ManagerSuspensionNotice.showLockedAction(context)
            : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFDDCC)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showInitialLoading)
                      const SizedBox(height: 18, width: 18, child: AppLoader())
                    else
                      RestaurantOpenStatusBadge(
                        openingHours: openingHours,
                        showNextOpening: false,
                      ),
                    if (!showInitialLoading) ...[
                      const SizedBox(height: 10),
                      if (isLoading)
                        const SizedBox(
                          height: 18,
                          width: 18,
                          child: AppLoader(),
                        )
                      else
                        Text(
                          todayLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF1C2331),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Modifier',
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isSuspended ? Icons.lock_outline : Icons.chevron_right,
                      color: accent,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
