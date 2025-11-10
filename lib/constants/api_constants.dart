class ApiConstants {
  static const String baseUrl = "https://fuelmate-staging.poscloud.co.zw/api";

  // Auth Endpoints
  static const String login = "$baseUrl/pos/login";
  static const String logout = "$baseUrl/auth/logout";
  static const String refreshToken = "$baseUrl/auth/refresh";

  // Add more modules here (users, products, etc.)
  static const String users = "$baseUrl/users";
  static const String stations = "$baseUrl/stations";
  static const String products = "$baseUrl/pos/products";
  static const String serviceStationsProducts = "$baseUrl/pos/products/service-station";
  // Device activation
  static const String deviceLaunch = "$baseUrl/pos/device-launch";
  // Change top-up
  static const String changeTopup = "$baseUrl/pos/change-topup";
  // Card balance enquiry
  static const String cardBalance = "$baseUrl/pos/card-balance";
  static const String setPin = "$baseUrl/pos/set-pin";
  // Attendant/operator code reset
  static const String attendantsResetCode = "$baseUrl/pos/attendants-reset-code";
  // Reports
  static const String posBatchCutoff = "$baseUrl/pos/batch-cutoff";
  static const String posLastSale = "$baseUrl/pos/last-sale"; // placeholder
  static const String posBatchAudit = "$baseUrl/pos/batch-audit"; // placeholder
  static const String posReversals = "$baseUrl/pos/reversals"; // placeholder

  // Coupons
  static const String validateCoupon = "$baseUrl/pos/validate-coupon";
}
