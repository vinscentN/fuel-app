class BuffaloBalanceRequest {
  final String cardNumber;
  final String? pin;

  BuffaloBalanceRequest({
    required this.cardNumber,
    this.pin,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'card_number': cardNumber,
    };

    if (pin != null && pin!.isNotEmpty) {
      data['pin'] = pin;
    }

    return data;
  }
}

class BuffaloBalanceResponse {
  final bool success;
  final String? message;
  final BalanceData? data;
  final String? error;

  BuffaloBalanceResponse({
    required this.success,
    this.message,
    this.data,
    this.error,
  });

  factory BuffaloBalanceResponse.fromJson(Map<String, dynamic> json) {
    return BuffaloBalanceResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null ? BalanceData.fromJson(json['data']) : null,
      error: json['error'],
    );
  }
}

class BalanceData {
  final String cardNumber;
  final List<CurrencyBalance> balances;
  final String? cardholderName;
  final String? cardStatus;

  BalanceData({
    required this.cardNumber,
    required this.balances,
    this.cardholderName,
    this.cardStatus,
  });

  factory BalanceData.fromJson(Map<String, dynamic> json) {
    return BalanceData(
      cardNumber: json['card_number'] ?? '',
      balances: json['balances'] != null
          ? (json['balances'] as List)
              .map((balance) => CurrencyBalance.fromJson(balance))
              .toList()
          : [],
      cardholderName: json['cardholder_name'],
      cardStatus: json['card_status'],
    );
  }
}

class CurrencyBalance {
  final String currencyCode;
  final String currencySymbol;
  final double balance;
  final String formatted;

  CurrencyBalance({
    required this.currencyCode,
    required this.currencySymbol,
    required this.balance,
    required this.formatted,
  });

  factory CurrencyBalance.fromJson(Map<String, dynamic> json) {
    return CurrencyBalance(
      currencyCode: json['currency_code'] ?? '',
      currencySymbol: json['currency_symbol'] ?? '',
      balance: _parseDouble(json['balance']) ?? 0.0,
      formatted: json['formatted'] ?? '',
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
