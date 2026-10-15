import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_time_box.dart';

class DayEditorTimeSection extends StatelessWidget {
  final List<TimeOfDay?> startTimes;
  final List<TimeOfDay?> endTimes;
  final void Function(int index, bool isStart) onPickTime;
  final void Function(int index)? onRemoveRange;

  const DayEditorTimeSection({
    super.key,
    required this.startTimes,
    required this.endTimes,
    required this.onPickTime,
    this.onRemoveRange,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder:
          (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < startTimes.length; i++) ...[
            _buildRangeRow(context, i),
            if (i < startTimes.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildRangeRow(BuildContext context, int index) {
    final showDeleteButton = onRemoveRange != null && index > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showDeleteButton)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              tooltip: 'Supprimer cette plage horaire',
              onPressed: () => onRemoveRange?.call(index),
            )
          else
            const SizedBox(width: 48),
          Expanded(
            flex: 1,
            child: AppTimeBox(
              time: startTimes[index],
              onTap: () => onPickTime(index, true),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '-',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 1,
            child: AppTimeBox(
              time: endTimes[index],
              onTap: () => onPickTime(index, false),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
