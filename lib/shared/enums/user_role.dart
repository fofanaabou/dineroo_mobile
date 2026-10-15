enum UserRole {
  customer,
  driver,
  guest,
  restaurantManager;

  String get backendRole {
    switch (this) {
      case UserRole.restaurantManager:
        return 'RESTAURANT_MANAGER';
      default:
        return name.toUpperCase();
    }
  }
}
