import 'package:flutter/material.dart';

Future<TimeOfDay?> showAppTimePicker(
  BuildContext context, {
  TimeOfDay? initialTime,
  String? helpText,
}) async {
  final result = await showTimePicker(
    context: context,
    initialTime: initialTime ?? TimeOfDay.now(),
    helpText: helpText,
    builder: (context, child) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      );
    },
  );
  return result;
}
