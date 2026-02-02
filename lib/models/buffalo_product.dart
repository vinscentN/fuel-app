class BuffaloProduct {
  final int id;
  final String name;
  final String description;
  final String sku;
  final String? imageUrl;
  final List<ProductPrice> prices;

  BuffaloProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.sku,
    this.imageUrl,
    required this.prices,
  });

  factory BuffaloProduct.fromJson(Map<String, dynamic> json) {
    return BuffaloProduct(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      sku: json['sku'],
      imageUrl: json['image_url'],
      prices: (json['prices'] as List)
          .map((price) => ProductPrice.fromJson(price))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sku': sku,
      'image_url': imageUrl,
      'prices': prices.map((price) => price.toJson()).toList(),
    };
  }

  ProductPrice? getPriceForCurrency(int currencyId) {
    try {
      return prices.firstWhere((price) => price.currencyId == currencyId);
    } catch (e) {
      return null;
    }
  }
}

class ProductPrice {
  final int currencyId;
  final String currencyCode;
  final String currencySymbol;
  final double price;
  final String formatted;

  ProductPrice({
    required this.currencyId,
    required this.currencyCode,
    required this.currencySymbol,
    required this.price,
    required this.formatted,
  });

  factory ProductPrice.fromJson(Map<String, dynamic> json) {
    return ProductPrice(
      currencyId: json['currency_id'],
      currencyCode: json['currency_code'],
      currencySymbol: json['currency_symbol'],
      price: _parseDouble(json['price']),
      formatted: json['formatted'],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'currency_id': currencyId,
      'currency_code': currencyCode,
      'currency_symbol': currencySymbol,
      'price': price,
      'formatted': formatted,
    };
  }
}
