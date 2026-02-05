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
    bool parseBool(dynamic v) {
      if (v is bool) return v;
      final s = v?.toString().toLowerCase();
      return s == 'true' || s == '1' || s == 'success' || s == 'ok';
    }

    Map<String, dynamic>? pickData() {
      final d = json['data'];
      if (d is Map<String, dynamic>) return d;
      if (json['balances'] is List || json['card_number'] != null) return json;
      return null;
    }

    return BuffaloBalanceResponse(
      success: parseBool(json['success'] ?? json['status']),
      message: json['message'],
      data: pickData() != null ? BalanceData.fromJson(pickData()!) : null,
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
    final rawBalances =
        (json['balances'] ?? json['wallet_balances'] ?? json['currencies']);
    List<CurrencyBalance> parsedBalances = [];
    if (rawBalances is List) {
      parsedBalances = rawBalances
          .map((balance) => CurrencyBalance.fromJson(balance))
          .toList();
    } else {
      // Fallback for meal-card payloads that return a single meal_balance value.
      final mealRaw = json['meal_balance'];
      final meal = CurrencyBalance._parseDouble(mealRaw);
      if (mealRaw != null) {
        final mealsInt = meal % 1 == 0 ? meal.toInt().toString() : meal.toString();
        parsedBalances = [
          CurrencyBalance(
            currencyCode: 'MEALS',
            currencySymbol: '',
            balance: meal,
            formatted: '$mealsInt meals',
          ),
        ];
      }
    }

    final rawName =
        (json['cardholder_name'] ?? json['employee_name'] ?? '').toString().trim();
    final rawStatus =
        (json['card_status'] ?? json['card_class'] ?? '').toString().trim();
    return BalanceData(
      cardNumber: json['card_number'] ?? '',
      balances: parsedBalances,
      cardholderName: rawName.isEmpty ? null : rawName,
      cardStatus: rawStatus.isEmpty ? null : rawStatus,
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
    final value = _parseDouble(
      json['balance'] ?? json['amount'] ?? json['value'],
    );
    final symbol = (json['currency_symbol'] ?? '').toString();
    final fallbackFormatted = symbol.isNotEmpty
        ? '$symbol${value.toStringAsFixed(2)}'
        : value.toStringAsFixed(2);
    return CurrencyBalance(
      currencyCode: (json['currency_code'] ??
              json['currency'] ??
              json['code'] ??
              '')
          .toString(),
      currencySymbol: symbol,
      balance: value,
      formatted: (json['formatted'] ?? fallbackFormatted).toString(),
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
