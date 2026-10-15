class ExternalMapDestination {
  final String label;
  final String query;
  final List<String> fallbackQueries;
  final double? latitude;
  final double? longitude;

  const ExternalMapDestination({
    required this.label,
    required this.query,
    this.fallbackQueries = const [],
    this.latitude,
    this.longitude,
  });

  bool get hasCoordinates => latitude != null && longitude != null;
}
