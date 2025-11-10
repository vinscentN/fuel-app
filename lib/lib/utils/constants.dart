// utils/constants.dart
class AppConstants {
  // API Endpoints (for future implementation)
  static const String baseUrl = 'https://api.fuelstation.com';
  static const String apiVersion = '/v1';

  // Authentication endpoints
  static const String loginEndpoint = '$baseUrl$apiVersion/auth/login';
  static const String logoutEndpoint = '$baseUrl$apiVersion/auth/logout';
  static const String refreshTokenEndpoint = '$baseUrl$apiVersion/auth/refresh';

  // Fuel endpoints
  static const String productsEndpoint = '$baseUrl$apiVersion/fuel/products';
  static const String currenciesEndpoint = '$baseUrl$apiVersion/fuel/currencies';
  static const String pricesEndpoint = '$baseUrl$apiVersion/fuel/prices';

  // Payment endpoints
  static const String cardPaymentEndpoint = '$baseUrl$apiVersion/payment/card';
  static const String cashPaymentEndpoint = '$baseUrl$apiVersion/payment/cash';
  static const String mobilePaymentEndpoint = '$baseUrl$apiVersion/payment/mobile';
  static const String transactionStatusEndpoint = '$baseUrl$apiVersion/payment/status';

  // Coupon endpoints
  static const String validateCouponEndpoint = '$baseUrl$apiVersion/coupons/validate';
  static const String redeemCouponEndpoint = '$baseUrl$apiVersion/coupons/redeem';

  // App Configuration
  static const String appName = 'Fuel Mate';
  static const String appVersion = '1.0.0';
  static const int apiTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;

  // Demo Credentials
  static const List<Map<String, String>> demoCredentials = [
    {'username': 'attendant1', 'password': '1234', 'role': 'attendant'},
    {'username': 'manager', 'password': 'admin', 'role': 'manager'},
    {'username': 'attendant2', 'password': '1234', 'role': 'attendant'},
  ];

  // Demo Coupon Codes
  static const List<String> demoCoupons = [
    'FUEL20',
    'SAVE50',
    'DIESEL10',
  ];

  // Validation Rules
  static const int minPasswordLength = 4;
  static const int maxTransactionAmount = 10000;
  static const int pinLength = 4;
  static RegExp mobileNumberRegex = RegExp(r'^\+263\d{9}$');
  static RegExp cardNumberRegex = RegExp(r'^\d{16}$');
}

// utils/validators.dart
class Validators {
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your username';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }
    return null;
  }

  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an amount';
    }
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'Please enter a valid amount';
    }
    if (amount > AppConstants.maxTransactionAmount) {
      return 'Amount cannot exceed \$${AppConstants.maxTransactionAmount}';
    }
    return null;
  }

  static String? validateMobileNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter mobile number';
    }
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    if (!AppConstants.mobileNumberRegex.hasMatch('+$cleaned')) {
      return 'Please enter a valid mobile number';
    }
    return null;
  }

  static String? validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter card number';
    }
    final cleaned = value.replaceAll(' ', '');
    if (!AppConstants.cardNumberRegex.hasMatch(cleaned)) {
      return 'Card number must be 16 digits';
    }
    return null;
  }

  static String? validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter CVV';
    }
    if (value.length != 3 || !RegExp(r'^\d{3}$').hasMatch(value)) {
      return 'CVV must be 3 digits';
    }
    return null;
  }

  static String? validateCouponCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter coupon code';
    }
    if (value.length < 3) {
      return 'Coupon code must be at least 3 characters';
    }
    return null;
  }
}