import 'package:intl/intl.dart';

/// Format DateTime in FR. e.g: '30 JANV. 2026, 12:30'
String formatDateTime(DateTime dateTime) {
  final day = dateTime.day.toString().padLeft(2, '0');
  final month = DateFormat('MMM', 'fr_FR').format(dateTime).toUpperCase();
  final year = dateTime.year.toString();
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$day $month $year, $hour:$minute';
}
