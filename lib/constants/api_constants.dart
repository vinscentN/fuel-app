class ApiConstants {
  // For local testing with physical device, use your computer's local IP
  // Your current IP: 172.19.74.143
  //static const String baseUrl = "http://10.107.91.143:8000/api/pos";


  static const String baseUrl = "https://gasman.poscloud.co.zw/api/pos";
  // static const String baseUrl = "http://127.0.0.1:8000/api/pos";

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

  // Gas Tank Endpoints
  static String gasTanksByStation(String serviceStationId) =>"$baseUrl/gas-tanks/$serviceStationId";
  static String receiveGasStock(String tankId) => "$baseUrl/gas-tanks/receive/$tankId";

  // Customer Endpoints
  static const String customers = "$baseUrl/customers";
}
