class RestaurantUnavailableException implements Exception {
  static const String message =
      'Ce restaurant n\'est pas disponible pour le moment.';

  final String restaurantId;

  const RestaurantUnavailableException(this.restaurantId);

  @override
  String toString() => message;
}
