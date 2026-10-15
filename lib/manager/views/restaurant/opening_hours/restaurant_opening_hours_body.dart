import 'package:dineroo_mobile/shared/common/constants/days_constants.dart';
import 'package:dineroo_mobile/shared/common/helpers/opening_hours_helper.dart';
import 'package:dineroo_mobile/shared/models/domain/opening_hours.dart';
import 'package:dineroo_mobile/manager/view_models/restaurant/manager_restaurant_view_model.dart';
import 'package:dineroo_mobile/manager/views/home/manager_suspension_banner.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'day_editor.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_button.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_snackbar.dart';

class RestaurantOpeningHoursBody extends StatefulWidget {
  final String restaurantId;
  const RestaurantOpeningHoursBody({super.key, required this.restaurantId});

  @override
  State<RestaurantOpeningHoursBody> createState() =>
      _RestaurantOpeningHoursBodyState();
}

class _RestaurantOpeningHoursBodyState extends State<RestaurantOpeningHoursBody> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _todayKey = GlobalKey();

  String get _todayDayKey => OpeningHoursHelper.currentDayKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _todayKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todayDayKey = _todayDayKey;
    final vm = context.watch<ManagerRestaurantViewModel>();
    final suspension = vm.suspension;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (suspension != null) ...[
            ManagerSuspensionBanner(suspension: suspension),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children:
                    DaysConstants.daysMap.keys.toList().map((dayKey) {
                      final isToday = dayKey == todayDayKey;
                      return Padding(
                        key: isToday ? _todayKey : null,
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _DayCard(
                          dayKey: dayKey,
                          isToday: isToday,
                          restaurantId: widget.restaurantId,
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            text: 'Enregistrer',
            isDisabled: vm.isSuspended,
            onPressed:
                vm.isSaving || vm.isSuspended
                    ? null
                    : () async {
                      await vm.saveOpeningHours(widget.restaurantId);
                      if (vm.error == null && context.mounted) {
                        AppSnackbar.success(
                          context,
                          'Horaires mis à jour avec succès',
                          bottomMargin: 80,
                        );
                        await vm.loadRestaurantState(widget.restaurantId);
                      } else if (context.mounted) {
                        AppSnackbar.error(
                          context,
                          vm.error ?? 'Erreur lors de la mise à jour.',
                          bottomMargin: 80,
                        );
                      }
                    },
            isLoading: vm.isSaving,
          ),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final String dayKey;
  final bool isToday;
  final String restaurantId;

  const _DayCard({
    required this.dayKey,
    required this.isToday,
    required this.restaurantId,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ManagerRestaurantViewModel>();

    final data = vm.openingHours.firstWhere(
      (h) => h.day == dayKey,
      orElse: () => OpeningHours(day: dayKey, timeRanges: []),
    );

    final initialRanges = data.timeRanges
        .map((t) => {'start': t.start, 'end': t.end})
        .toList();

    return DayEditor(
      day: DaysConstants.getDayLabel(dayKey),
      initialRanges: initialRanges,
      isToday: isToday,
      onSave: (updatedRanges) {
        vm.setDayOpeningHours(
          dayKey,
          updatedRanges
              .map(
                (r) => TimeRange(start: r['start'], end: r['end']),
              )
              .toList(),
        );
      },
    );
  }
}
