class BuffaloCardInfo {
  final String cardNumber;
  final String firstName;
  final String lastName;
  final String cardType;
  final String cardClass;
  final int mealBalance;
  final int? productId;

  BuffaloCardInfo({
    required this.cardNumber,
    required this.firstName,
    required this.lastName,
    required this.cardType,
    required this.cardClass,
    required this.mealBalance,
    this.productId,
  });

  factory BuffaloCardInfo.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    final nestedProduct = json['product'];
    final nestedProductId = nestedProduct is Map<String, dynamic>
        ? nestedProduct['id']
        : null;

    return BuffaloCardInfo(
      cardNumber: json['card_number'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      cardType: json['card_type'] ?? '',
      cardClass: json['card_class'] ?? '',
      mealBalance: json['meal_balance'] ?? 0,
      productId: parseInt(
        json['product_id'] ??
            json['meal_product_id'] ??
            json['default_product_id'] ??
            nestedProductId,
      ),
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
      'product_id': productId,
    };
  }

  bool get isHodProxyCard => cardClass == 'HOD PROXY CARD';

  String get fullName => '$firstName $lastName';
}
