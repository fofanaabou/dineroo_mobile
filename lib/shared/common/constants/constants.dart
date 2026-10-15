class ApiConstants {
  static const String apiVersion = '/v1';
  static const String restaurants = '$apiVersion/restaurants';
  static const String users = '$apiVersion/users';
  static const String uploadUserFile = '$apiVersion/users/upload-file';
  static const String payments = '$apiVersion/payments';
  static const String wallets = '$apiVersion/wallets';
  static const String payouts = '$apiVersion/payouts';
  static const String orders = '$apiVersion/orders';
  static const String orderDetails = '$apiVersion/order-details';
  static const String customers = '$apiVersion/customers';
  static const String restaurantOrders = '$apiVersion/restaurant-orders';
  static const String drivers = '$apiVersion/drivers';
  static const String deliveries = '$apiVersion/deliveries';
  static const String appVersionPolicy = '$apiVersion/app/version-policy';

  static String userById(String userId) => '$users/$userId';
  static String userByPhone(String telephone) => '$users/phone/$telephone';
  static String userSendCode() => '$users/send-code';
  static String userValidateCode() => '$users/validate-code';
  static String userVerifyCode() => '$users/verify-code';
  static String userToken() => '$users/token';
  static String userRefreshToken() => '$users/token/refresh';
  static String userLogout() => '$users/me/logout';
  static String userDeviceTokens(String userId) =>
      '${userById(userId)}/device-tokens';
  static String userResetPinWithPhone(String telephone) =>
      '${userByPhone(telephone)}/reset-code-pin-with-phone';
  static String userResetPinWithId(String userId) =>
      '${userById(userId)}/reset-code-pin-with-id';
  static String userDownloadFile(String userId) =>
      '${userById(userId)}/download-file';

  static String restaurantById(String restaurantId) =>
      '$restaurants/$restaurantId';
  static String restaurantMenus(String restaurantId) =>
      '${restaurantById(restaurantId)}/menus';
  static String restaurantMenuById(String restaurantId, String menuId) =>
      '${restaurantMenus(restaurantId)}/$menuId';
  static String restaurantCatalogueMenuById(
    String restaurantId,
    String menuId,
  ) => '${restaurantById(restaurantId)}/catalogue/menus/$menuId';
  static String restaurantCatalogueMenus(String restaurantId) =>
      '${restaurantById(restaurantId)}/catalogue/menus';
  static String restaurantCatalogueProducts(String restaurantId) =>
      '${restaurantById(restaurantId)}/catalogue/products';
  static String restaurantCatalogueProductById(
    String restaurantId,
    String productId,
  ) => '${restaurantById(restaurantId)}/catalogue/products/$productId';
  static String restaurantCatalogueItemAvailability(
    String restaurantId,
    String menuId,
    String groupId,
    String itemId,
  ) =>
      '${restaurantById(restaurantId)}/catalogue/menus/$menuId/groups/$groupId/items/$itemId';
  static String restaurantProducts(String restaurantId) =>
      '${restaurantById(restaurantId)}/products';
  static String restaurantProductById(String restaurantId, String productId) =>
      '${restaurantProducts(restaurantId)}/$productId';
  static String restaurantOrderAction(
    String restaurantId,
    String orderId,
    String action,
  ) => '${restaurantById(restaurantId)}/orders/$orderId/$action';
  static String restaurantOrderStatus(String restaurantId, String orderId) =>
      '${restaurantById(restaurantId)}/orders/$orderId/status';
  static String deliveryValidatePickupOtp(String orderId) =>
      '$deliveries/orders/$orderId/pickup-otp/validate';

  static String customerOrders(String customerId) =>
      '$customers/$customerId/orders';
  static String orderById(String orderId) => '$orders/$orderId';
  static String ordersBatch() => '$orders/batch';
  static String orderEstimate() => '$orders/estimate';
  static String paymentById(String paymentId) => '$payments/$paymentId';
  static String walletByCustomerId(String customerId) =>
      '$wallets/customers/$customerId';
  static String restaurantPayoutSummary(String restaurantId) =>
      '$payouts/restaurants/$restaurantId/summary';
  static String driverPayoutSummary(String driverId) =>
      '$payouts/drivers/$driverId/summary';
  static String restaurantOrdersByRestaurantId(String restaurantId) =>
      '$restaurantOrders/$restaurantId/orders';
  static String restaurantEarnings(String restaurantId) =>
      '$restaurantOrders/$restaurantId/earnings';
  static String driverById(String driverId) => '$drivers/$driverId';
  static String driverDeliveries(String driverId) =>
      '${driverById(driverId)}/deliveries';
  static String driverEarnings(String driverId) =>
      '${driverById(driverId)}/earnings';
  static String deliveryAssignDriver() => '$deliveries/assign-driver';
  static String deliveryStatus(String deliveryId) =>
      '$deliveries/$deliveryId/status';
}

class Constants {
  static const String userAgentPackageName = 'com.dineroo.app';
  static const String guineaCountryCode = '+224';
  static const String supportPhoneNumber = '+224611875748';
}

const double maxDeliveryDistanceKm = 10.0;
