// models/fuel_product.dart
class FuelProduct {
  final String id;
  final String name;
  final String type;
  final String description;
  final String iconPath;
  final Map<String, double> prices; // Currency code -> price
  final bool isAvailable;

  FuelProduct({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.iconPath,
    required this.prices,
    this.isAvailable = true,
  });

  factory FuelProduct.fromJson(Map<String, dynamic> json) {
    return FuelProduct(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      description: json['description'],
      iconPath: json['iconPath'],
      prices: Map<String, double>.from(json['prices']),
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'description': description,
      'iconPath': iconPath,
      'prices': prices,
      'isAvailable': isAvailable,
    };
  }
}
