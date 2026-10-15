class RestaurantOpenStatusCache {
  final bool isOpen;
  final DateTime timestamp;

  RestaurantOpenStatusCache(this.isOpen, this.timestamp);

  bool isValid(Duration ttl) {
    return DateTime.now().difference(timestamp) < ttl;
  }
}
