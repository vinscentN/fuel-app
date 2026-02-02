class BuffaloCardInfo {
  final String cardNumber;
  final String firstName;
  final String lastName;
  final String cardType;
  final String cardClass;
  final int mealBalance;

  BuffaloCardInfo({
    required this.cardNumber,
    required this.firstName,
    required this.lastName,
    required this.cardType,
    required this.cardClass,
    required this.mealBalance,
  });

  factory BuffaloCardInfo.fromJson(Map<String, dynamic> json) {
    return BuffaloCardInfo(
      cardNumber: json['card_number'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      cardType: json['card_type'] ?? '',
      cardClass: json['card_class'] ?? '',
      mealBalance: json['meal_balance'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'card_number': cardNumber,
      'first_name': firstName,
      'last_name': lastName,
      'card_type': cardType,
      'card_class': cardClass,
      'meal_balance': mealBalance,
    };
  }

  bool get isHodProxyCard => cardClass == 'HOD PROXY CARD';

  String get fullName => '$firstName $lastName';
}
