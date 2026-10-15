class OpeningHours {
  final String day;
  final List<TimeRange> timeRanges;

  OpeningHours({required this.day, required this.timeRanges});

  factory OpeningHours.fromJson(Map<String, dynamic> json) {
    return OpeningHours(
      day: json['day'],
      timeRanges:
          (json['timeRanges'] as List<dynamic>? ?? [])
              .map((e) => TimeRange.fromJson(e))
              .toList(),
    );
  }
}

class TimeRange {
  final String start;
  final String end;

  TimeRange({required this.start, required this.end});

  factory TimeRange.fromJson(Map<String, dynamic> json) {
    return TimeRange(start: json['start'], end: json['end']);
  }
}
