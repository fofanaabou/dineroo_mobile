class TimeRangeDto {
  final String start;
  final String end;

  TimeRangeDto({required this.start, required this.end});

  factory TimeRangeDto.fromJson(Map<String, dynamic> json) {
    return TimeRangeDto(start: json['start'] ?? '', end: json['end'] ?? '');
  }
}

class OpeningHoursDto {
  final String day;
  final List<TimeRangeDto> timeRanges;

  OpeningHoursDto({required this.day, required this.timeRanges});

  factory OpeningHoursDto.fromJson(Map<String, dynamic> json) {
    return OpeningHoursDto(
      day: json['day'],
      timeRanges:
          (json['timeRanges'] as List)
              .map((e) => TimeRangeDto.fromJson(e))
              .toList(),
    );
  }
}
