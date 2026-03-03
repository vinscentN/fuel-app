class ApiConstants {
  // For local testing with physical device, use your computer's local IP
  static const String baseUrl = "https://gasmate-sandbox.poscloud.co.zw/api/pos";
  //static const String baseUrl = "http://127.0.0.1:8000/api/pos";
  // Auth Endpoints
  static const String mobileLogin = "$baseUrl/login";
  static const String login = "$baseUrl/login";
  static const String logout = "$baseUrl/auth/logout";
  static const String refreshToken = "$baseUrl/auth/refresh";

  // Add more modules here (users, products, etc.)
  static const String users = "$baseUrl/users";
  static const String stations = "$baseUrl/stations";
  static const String products = "$baseUrl/products";
  static const String serviceStationsProducts = "$baseUrl/products/service-station";
  // Device activation
  static const String deviceLaunch = "$baseUrl/device-launch";
  // Change top-up
  static const String changeTopup = "$baseUrl/change-topup";
  // Card balance enquiry
  static const String cardBalance = "$baseUrl/card-balance";
  static const String setPin = "$baseUrl/set-pin";
  // Attendant/operator code reset
  static const String attendantsResetCode = "$baseUrl/attendants-reset-code";
  static const String resetOperatorCode = "$baseUrl/reset-operator-code";
  // Reports
  static const String posBatchCutoff = "$baseUrl/batch-cutoff";
  static const String posLastSale = "$baseUrl/last-sale"; // placeholder
  static const String posBatchAudit = "$baseUrl/batch-audit"; // placeholder
  static const String posReversals = "$baseUrl/reversals"; // placeholder

  // Coupons
  static const String validateCoupon = "$baseUrl/validate-coupon";

  // Site collections
  static const String siteCollections = "$baseUrl/site-collections";
  static const String siteCollectionsComplete = "$baseUrl/site-collections/complete";
  static const String siteCollectionsPendingGrouped = "$baseUrl/site-collections/pending?grouped=1";
  static const String siteCollectionsPickedUpGrouped = "$baseUrl/site-collections/picked-up?grouped=1";

  // Gas Tank Endpoints
  static String gasTanksByStation(String serviceStationId) =>"$baseUrl/gas-tanks/$serviceStationId";
  static String receiveGasStock(String tankId) => "$baseUrl/gas-tanks/receive/$tankId";

  // Customer Endpoints
  static const String customers = "$baseUrl/customers";

  // Delivery Order Endpoints
  static const String deliveryOrdersAssigned = "$baseUrl/delivery-orders/assigned";
  static const String deliveryOrdersHome = "$baseUrl/delivery-orders/home/assigned";
  static const String deliveryOrdersCommercial = "$baseUrl/delivery-orders/commercial/assigned";
  static const String deliveryOrdersSite = "$baseUrl/delivery-orders/site/assigned";
  static String deliveryOrderUpdateStatus(int id) =>
      "$baseUrl/delivery-orders/$id/status";
  static String deliveryOrderUpdateItemWeight(int orderId, int itemId) =>
      "$baseUrl/delivery-orders/$orderId/items/$itemId/actual-weight";

  // Swap assignment endpoints
  static String swapAssignments(int orderId) =>
      "$baseUrl/delivery-orders/$orderId/swap-assignments";
  static String swapAssignmentReturn(int orderId, int assignmentId) =>
      "$baseUrl/delivery-orders/$orderId/swap-assignments/$assignmentId/return";
}
