class GasTank {
  final int id;
  final int serviceStationId;
  final String serviceStationName;
  final String productId;
  final String productName;
  final String name;
  final double capacity;
  final String unit;
  final String status;
  final double currentVolume;
  final double currentWeight;
  final double availableSpace;
  final CylinderType? cylinderType;
  final Product? product;
  final String? trackingCode;

  GasTank({
    required this.id,
    required this.serviceStationId,
    required this.serviceStationName,
    required this.productId,
    required this.productName,
    required this.name,
    required this.capacity,
    required this.unit,
    required this.status,
    required this.currentVolume,
    this.currentWeight = 0,
    required this.availableSpace,
    this.cylinderType,
    this.product,
    this.trackingCode,
  });

  factory GasTank.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse integers
    int safeParseInt(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      try {
        return int.parse(value.toString());
      } catch (e) {
        return defaultValue;
      }
    }

    // Helper function to safely parse doubles
    double safeParseDouble(dynamic value, double defaultValue) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      try {
        return double.parse(value.toString());
      } catch (e) {
        return defaultValue;
      }
    }

    // Extract service_station info
    final serviceStation = json['service_station'];
    int serviceStationId = 0;
    String serviceStationName = '';

    if (serviceStation is Map) {
      serviceStationId = safeParseInt(serviceStation['id'], 0);
      serviceStationName = serviceStation['name']?.toString() ?? '';
    } else if (json['service_station_id'] != null) {
      serviceStationId = safeParseInt(json['service_station_id'], 0);
      serviceStationName = serviceStation?.toString() ?? '';
    }

    // Extract product info
    final product = json['product'];
    String productId = '--';
    String productName = '--';

    if (product is Map) {
      productId = product['id']?.toString() ?? '--';
      productName = product['name']?.toString() ?? '--';
    } else if (json['product_id'] != null) {
      productId = json['product_id']?.toString() ?? '--';
      productName = json['product_name']?.toString() ?? '--';
    }

    return GasTank(
      id: safeParseInt(json['id'], 0),
      serviceStationId: serviceStationId,
      serviceStationName: serviceStationName,
      productId: productId,
      productName: productName,
      name: json['name'] ?? '',
      capacity: safeParseDouble(json['capacity'], 0),
      unit: json['unit'] ?? 'KG',
      status: json['status'] ?? 'ACTIVE',
      currentVolume: safeParseDouble(json['current_volume'], 0),
      currentWeight: safeParseDouble(json['current_weight'], 0),
      availableSpace: safeParseDouble(json['available_space'], 0),
      cylinderType: json['cylinder_type'] != null
          ? CylinderType.fromJson(json['cylinder_type'])
          : null,
      product: json['product'] != null && json['product'] is Map
          ? Product.fromJson(json['product'])
          : null,
      trackingCode: json['tracking_code'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'service_station_id': serviceStationId,
    'service_station': serviceStationName,
    'product_id': productId,
    'product_name': productName,
    'name': name,
    'capacity': capacity,
    'unit': unit,
    'status': status,
    'current_volume': currentVolume,
    'current_weight': currentWeight,
    'available_space': availableSpace,
    'cylinder_type': cylinderType?.toJson(),
    'product': product?.toJson(),
    'tracking_code': trackingCode,
  };

  double get percentageFull {
    if (capacity == 0) return 0;
    return (currentVolume / capacity) * 100;
  }

  String get formattedCapacity => '${capacity.toStringAsFixed(0)} $unit';

  String get formattedCurrentVolume => '${currentVolume.toStringAsFixed(0)} $unit';

  String get formattedAvailableSpace => '${availableSpace.toStringAsFixed(0)} $unit';

  bool get isActive => status == 'ACTIVE';

  bool get hasProduct => productId != '--' && productId.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GasTank &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class CylinderType {
  final int id;
  final String name;
  final String? description;

  CylinderType({
    required this.id,
    required this.name,
    this.description,
  });

  factory CylinderType.fromJson(Map<String, dynamic> json) {
    return CylinderType(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}

class Product {
  final int id;
  final String name;
  final ProductType? productType;
  final String? price;
  final String? unitOfMeasure;

  Product({
    required this.id,
    required this.name,
    this.productType,
    this.price,
    this.unitOfMeasure,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      productType: json['product_type'] != null
          ? ProductType.fromJson(json['product_type'])
          : null,
      price: json['price']?.toString(),
      unitOfMeasure: json['unit_of_measure'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'product_type': productType?.toJson(),
      'price': price,
      'unit_of_measure': unitOfMeasure,
    };
  }
}

class ProductType {
  final int id;
  final String name;

  ProductType({
    required this.id,
    required this.name,
  });

  factory ProductType.fromJson(Map<String, dynamic> json) {
    return ProductType(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
