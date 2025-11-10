class Product {
  final String id;
  final String productName;
  final String productCode;
  final double price;
  final String currencyCode;
  final String serviceStationId;
  final String serviceStationName;
  final String? unitOfMeasure; // e.g., 'L', 'KG'

  Product({
    required this.id,
    required this.productName,
    required this.productCode,
    required this.price,
    required this.currencyCode,
    required this.serviceStationName,
    required this.serviceStationId,
    this.unitOfMeasure,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      productName: json['product_name'],
      productCode: json['product_code'],
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      currencyCode: json['currency_code'],
      serviceStationId: json['service_station_id'].toString(),
      serviceStationName: json['service_station_name'],
      unitOfMeasure: json['unit_of_measure']?.toString(),
    );
  }
}
