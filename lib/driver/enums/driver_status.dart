enum DriverStatus {
  offline('OFFLINE'),
  online('ONLINE'),
  onDelivery('ON_DELIVERY');

  final String apiValue;
  const DriverStatus(this.apiValue);

  static DriverStatus fromApi(String? value) {
    if (value == null || value.trim().isEmpty) {
      return DriverStatus.offline;
    }

    final v = value.trim().toUpperCase();
    switch (v) {
      case 'ONLINE':
        return DriverStatus.online;
      case 'ON_DELIVERY':
        return DriverStatus.onDelivery;
      case 'OFFLINE':
      default:
        return DriverStatus.offline;
    }
  }

  @override
  String toString() => apiValue;
}
