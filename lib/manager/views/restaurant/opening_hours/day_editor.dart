import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/common/colors.dart';
import 'package:dineroo_mobile/shared/common/helpers/opening_hours_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_switch.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_snackbar.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_time_picker.dart';
import 'day_editor_time_section.dart';

class DayEditor extends StatefulWidget {
  final String day;
  final List<Map<String, dynamic>>? initialRanges;
  final void Function(List<Map<String, dynamic>>) onSave;
  final bool isToday;

  const DayEditor({
    super.key,
    required this.day,
    required this.onSave,
    this.initialRanges,
    this.isToday = false,
  });

  @override
  State<DayEditor> createState() => _DayEditorState();
}

class _DayEditorState extends State<DayEditor> {
  List<TimeOfDay?> startTimes = [null];
  List<TimeOfDay?> endTimes = [null];
  bool isClosed = false;

  @override
  void initState() {
    super.initState();
    _loadInitialValues();
  }

  void _loadInitialValues() {
    final ranges = widget.initialRanges ?? [];

    if (ranges.isEmpty ||
        ranges.every((r) => r['start'] == '' || r['end'] == '')) {
      isClosed = true;
      startTimes = [null];
      endTimes = [null];
    } else {
      isClosed = false;
      startTimes = [];
      endTimes = [];
      for (final r in ranges) {
        startTimes.add(OpeningHoursHelper.parseTimeOfDay(r['start']));
        endTimes.add(OpeningHoursHelper.parseTimeOfDay(r['end']));
      }
      if (startTimes.isEmpty) {
        startTimes = [null];
        endTimes = [null];
      }
    }
  }

  Future<void> _pickTime(int index, bool isStart) async {
    final current = isStart
        ? (startTimes[index] ?? TimeOfDay.now())
        : (endTimes[index] ?? TimeOfDay.now());

    final result = await showAppTimePicker(
      context,
      initialTime: current,
      helpText: isStart
          ? 'Sélectionner l’heure de début'
          : 'Sélectionner l’heure de fin',
    );

    if (result == null) return;

    setState(() {
      if (isStart) {
        startTimes[index] = result;
        if (endTimes[index] != null &&
            !OpeningHoursHelper.isValidRange(
              startTimes[index],
              endTimes[index],
            )) {
          endTimes[index] = null;
          AppSnackbar.error(
            context,
            'L’heure de fin ne peut pas être identique à l’heure de début.',
            bottomMargin: 80,
          );
        }
      } else {
        if (startTimes[index] != null &&
            !OpeningHoursHelper.isValidRange(startTimes[index], result)) {
          AppSnackbar.error(
            context,
            'L’heure de fin doit être différente de l’heure de début.',
            bottomMargin: 80,
          );
          return;
        }
        endTimes[index] = result;
      }

      if (OpeningHoursHelper.isOverlappingRangeList(startTimes, endTimes)) {
        if (isStart) {
          startTimes[index] = null;
        } else {
          endTimes[index] = null;
        }
        AppSnackbar.error(
          context,
          'Les deux plages horaires ne peuvent pas se chevaucher.',
          bottomMargin: 80,
        );
      }

      _saveIfComplete();
    });
  }

  void _addTimeRange() {
    if (startTimes.length >= 2) return;
    setState(() {
      startTimes.add(null);
      endTimes.add(null);
    });
  }

  void _removeTimeRange(int index) {
    if (index == 0 || startTimes.length <= 1) return;
    setState(() {
      startTimes.removeAt(index);
      endTimes.removeAt(index);
    });
    _saveIfComplete();
  }

  void _saveIfComplete() {
    if (isClosed) {
      widget.onSave([]);
      return;
    }

    final validRanges = <Map<String, dynamic>>[];
    for (int i = 0; i < startTimes.length; i++) {
      if (startTimes[i] != null && endTimes[i] != null) {
        validRanges.add({
          'start': OpeningHoursHelper.formatTime(startTimes[i]!),
          'end': OpeningHoursHelper.formatTime(endTimes[i]!),
        });
      }
    }
    widget.onSave(validRanges);
  }

  void _handleSwitchChange(bool isOpen) {
    setState(() => isClosed = !isOpen);
    if (isClosed) {
      widget.onSave([]);
    } else {
      _saveIfComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = !isClosed;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: widget.isToday
            ? Border.all(color: AppColors.orange, width: 1.4)
            : null,
        boxShadow: [
          BoxShadow(
            color: widget.isToday
                ? AppColors.orange.withValues(alpha: 0.16)
                : Colors.grey.shade200,
            blurRadius: widget.isToday ? 14 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(context, isOpen),
          const SizedBox(height: 12),
          if (isOpen)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DayEditorTimeSection(
                  startTimes: startTimes,
                  endTimes: endTimes,
                  onPickTime: _pickTime,
                  onRemoveRange: _removeTimeRange,
                ),
                if (startTimes.length < 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton.icon(
                      onPressed: _addTimeRange,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Ajouter une autre plage'),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );

    return card;
  }

  Widget _dayTitle(BuildContext context) {
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          widget.day,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        if (widget.isToday)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Aujourd'hui",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.orange.withValues(alpha: 0.85),
              ),
            ),
          ),
      ],
    );
  }

  Widget _header(BuildContext context, bool isOpen) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _dayTitle(context)),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _handleSwitchChange(!isOpen),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSwitch(value: isOpen, onChanged: _handleSwitchChange),
              const SizedBox(width: 8),
              Text(
                isOpen ? 'Ouvert' : 'Fermé',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isOpen ? Colors.green : Colors.red.shade400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
