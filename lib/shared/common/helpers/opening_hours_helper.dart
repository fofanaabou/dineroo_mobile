import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/models/domain/opening_hours.dart';
import 'package:intl/intl.dart';

class OpeningHoursHelper {
  /// Checks if the restaurant is currently open
  static bool restaurantIsOpen(List<OpeningHours> openingHours) {
    final now = DateTime.now();
    return currentDayRanges(
      openingHours,
    ).any((range) => _isWithinRange(now, range));
  }

  /// Returns the next opening time
  static String? nextOpeningHour(List<OpeningHours> openingHours) {
    final nextOpening = nextOpeningDateTime(openingHours);
    if (nextOpening == null) return null;
    return DateFormat('HH:mm').format(nextOpening);
  }

  /// Returns the next opening datetime
  static DateTime? nextOpeningDateTime(List<OpeningHours> openingHours) {
    final now = DateTime.now();

    // Check the full weekly schedule, starting from today.
    for (int i = 0; i < 8; i++) {
      final day = now.add(Duration(days: i));
      final dayName = DateFormat('EEEE').format(day).toUpperCase();

      final dayRanges = openingHours
          .where((h) => h.day.toUpperCase() == dayName)
          .expand((h) => h.timeRanges)
          .toList();

      for (final range in dayRanges) {
        final start = _parseHour(range.start);
        if (start == null) continue;

        final adjustedStart = start.add(Duration(days: i));

        if (now.isBefore(adjustedStart)) {
          return adjustedStart;
        }
      }
    }
    return null;
  }

  static String? nextOpeningLabel(List<OpeningHours> openingHours) {
    final nextOpening = nextOpeningDateTime(openingHours);
    if (nextOpening == null) return null;

    final now = DateTime.now();
    final nextDate = DateTime(
      nextOpening.year,
      nextOpening.month,
      nextOpening.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final time = DateFormat('HH:mm').format(nextOpening);

    if (nextDate == today) return 'Ouvre aujourd’hui à $time';
    if (nextDate == tomorrow) return 'Ouvre demain à $time';

    final day = DateFormat('EEEE', 'fr_FR').format(nextOpening);
    return 'Ouvre $day à $time';
  }

  /// Returns true when the restaurant reopens within [maxDelay]
  static bool restaurantOpensWithin(
    List<OpeningHours> openingHours,
    Duration maxDelay,
  ) {
    final nextOpening = nextOpeningDateTime(openingHours);
    if (nextOpening == null) return false;

    final now = DateTime.now();
    if (!nextOpening.isAfter(now)) return false;

    return nextOpening.difference(now) <= maxDelay;
  }

  /// Returns the day key of the current day (e.g. 'MONDAY').
  static String currentDayKey() {
    return DateFormat('EEEE').format(DateTime.now()).toUpperCase();
  }

  /// Returns the time ranges for the current day
  static List<TimeRange> currentDayRanges(List<OpeningHours> openingHours) {
    if (openingHours.isEmpty) return [];
    final currentDay = currentDayKey();

    final todayHours = openingHours
        .where((h) => h.day.toUpperCase() == currentDay)
        .toList();
    return todayHours.expand((h) => h.timeRanges).toList();
  }

  static String formatRanges(List<TimeRange> ranges) {
    if (ranges.isEmpty) return 'Fermé';
    return ranges.map((range) => '${range.start} - ${range.end}').join(' / ');
  }

  /// Checks if the current time is within a given time range
  static bool _isWithinRange(DateTime now, TimeRange range) {
    final startTime = _parseHour(range.start);
    final endTime = _parseHour(range.end, isEnd: true, startTime: startTime);
    if (startTime == null || endTime == null) return false;

    // Normal case (same day)
    if (endTime.isAfter(startTime)) {
      return !now.isBefore(startTime) && !now.isAfter(endTime);
    }

    // Cross-midnight case (e.g., 18:00 - 02:00)
    return !now.isBefore(startTime) || !now.isAfter(endTime);
  }

  /// Parses "HH:mm" string into a DateTime object
  static DateTime? _parseHour(
    String time, {
    bool isEnd = false,
    DateTime? startTime,
  }) {
    final cleanedTime = time.trim().toLowerCase();
    if (cleanedTime.isEmpty ||
        cleanedTime == 'closed' ||
        cleanedTime == 'fermé') {
      return null;
    }

    final now = DateTime.now();
    final parts = cleanedTime.split(':');
    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0].trim()) ?? 0;
    final minute = int.tryParse(parts[1].trim()) ?? 0;

    var dateTime = DateTime(now.year, now.month, now.day, hour, minute);

    // If the end time is before the start time (e.g., 23:00 → 02:00)
    if (isEnd && startTime != null && dateTime.isBefore(startTime)) {
      dateTime = dateTime.add(const Duration(days: 1));
    }
    // dateTime = dateTime.add(Duration(hours: 16));
    return dateTime;
  }

  /// Converts TimeOfDay to "HH:mm" string
  static String formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  /// Parses "HH:mm" string to TimeOfDay
  static TimeOfDay? parseTimeOfDay(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  /// Converts TimeOfDay to total minutes (useful for comparisons)
  static int toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  /// Checks if time range is valid (start != end)
  static bool isValidRange(TimeOfDay? start, TimeOfDay? end) {
    if (start == null || end == null) return false;
    return toMinutes(end) != toMinutes(start);
  }

  /// Checks if two time ranges overlap
  static bool isOverlappingRangeList(
    List<TimeOfDay?> startTimes,
    List<TimeOfDay?> endTimes,
  ) {
    if (startTimes.length < 2 || endTimes.length < 2) return false;

    final s1 = startTimes[0];
    final e1 = endTimes[0];
    final s2 = startTimes[1];
    final e2 = endTimes[1];

    if (s1 == null || e1 == null || s2 == null || e2 == null) return false;

    final s1Min = toMinutes(s1);
    final e1Min = toMinutes(e1);
    final s2Min = toMinutes(s2);
    final e2Min = toMinutes(e2);

    return (s1Min < e2Min && e1Min > s2Min);
  }
}
