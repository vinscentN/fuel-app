// models/currency.dart
class Currency {
  final String code;
  final String name;
  final String symbol;
  final double exchangeRate;
  final bool isActive;

  Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.exchangeRate,
    this.isActive = true,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      code: json['code'],
      name: json['name'],
      symbol: json['symbol'],
      exchangeRate: json['exchangeRate'].toDouble(),
      isActive: json['isActive'] ?? true,
    );
  }

  static get usd => null;

  static get zwg => null;

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'symbol': symbol,
      'exchangeRate': exchangeRate,
      'isActive': isActive,
    };
  }
}
