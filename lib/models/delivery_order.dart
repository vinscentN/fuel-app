class DeliveryOrder {
  final int id;
  final String orderType;
  final String status;
  final String? expectedDeliveryDate;
  final String? expectedDeliveryTime;
  final String? distanceKm;
  final String? deliveryFee;
  final String? notes;
  final int? assignedDriverId;
  final DateTime? createdAt;
  final CustomerInfo? customer;
  final LocationInfo? location;
  final List<DeliveryOrderItem> items;

  DeliveryOrder({
    required this.id,
    required this.orderType,
    required this.status,
    this.expectedDeliveryDate,
    this.expectedDeliveryTime,
    this.distanceKm,
    this.deliveryFee,
    this.notes,
    this.assignedDriverId,
    this.createdAt,
    this.customer,
    this.location,
    required this.items,
  });

  factory DeliveryOrder.fromJson(Map<String, dynamic> json) {
    return DeliveryOrder(
      id: json['id'] ?? 0,
      orderType: (json['order_type'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      expectedDeliveryDate: json['expected_delivery_date']?.toString(),
      expectedDeliveryTime: json['expected_delivery_time']?.toString(),
      distanceKm: json['distance_km']?.toString(),
      deliveryFee: json['delivery_fee']?.toString(),
      notes: json['notes']?.toString(),
      assignedDriverId: json['assigned_driver_id'] as int?,
      createdAt: _parseDate(json['created_at']),
      customer: json['customer'] != null
          ? CustomerInfo.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      location: json['location'] != null
          ? LocationInfo.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => DeliveryOrderItem.fromJson(item))
              .toList() ??
          [],
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class CustomerInfo {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? customerType;

  CustomerInfo({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.customerType,
  });

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    return CustomerInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      customerType: json['customer_type']?.toString(),
    );
  }
}

class LocationInfo {
  final int id;
  final String label;
  final String fullAddress;
  final String? latitude;
  final String? longitude;

  LocationInfo({
    required this.id,
    required this.label,
    required this.fullAddress,
    this.latitude,
    this.longitude,
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      id: json['id'] ?? 0,
      label: json['label']?.toString() ?? '',
      fullAddress: json['full_address']?.toString() ?? '',
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
    );
  }
}

class DeliveryOrderItem {
  final int id;
  final String quantity;
  final String? unitPrice;
  final String? total;
  final ProductInfo? product;

  DeliveryOrderItem({
    required this.id,
    required this.quantity,
    this.unitPrice,
    this.total,
    this.product,
  });

  factory DeliveryOrderItem.fromJson(Map<String, dynamic> json) {
    return DeliveryOrderItem(
      id: json['id'] ?? 0,
      quantity: (json['quantity'] ?? '0').toString(),
      unitPrice: json['unit_price']?.toString(),
      total: json['total']?.toString(),
      product: json['product'] != null
          ? ProductInfo.fromJson(json['product'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ProductInfo {
  final int id;
  final String name;
  final String? unitOfMeasure;
  final String? price;

  ProductInfo({
    required this.id,
    required this.name,
    this.unitOfMeasure,
    this.price,
  });

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      unitOfMeasure: json['unit_of_measure']?.toString(),
      price: json['price']?.toString(),
    );
  }
}
