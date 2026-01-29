class DriverOrder {
  final String type;
  final int id;
  final String status;
  final String? orderType;
  final String? requestCode;
  final String? deliveryCode;
  final DriverOrderSite? site;
  final DriverOrderSupplier? supplier;
  final DriverOrderBobtail? bobtail;
  final int? assignedDriverId;
  final String? unitCostPrice;
  final String? productWeight;
  final String? actualKg;
  final String? unitCost;
  final DateTime? requestCreatedAt;
  final DateTime? deliveryDoneAt;
  final DateTime? createdAt;

  DriverOrder({
    required this.type,
    required this.id,
    required this.status,
    this.orderType,
    this.requestCode,
    this.deliveryCode,
    this.site,
    this.supplier,
    this.bobtail,
    this.assignedDriverId,
    this.unitCostPrice,
    this.productWeight,
    this.actualKg,
    this.unitCost,
    this.requestCreatedAt,
    this.deliveryDoneAt,
    this.createdAt,
  });

  factory DriverOrder.fromJson(Map<String, dynamic> json) {
    final gasOrder = json['gas_order'] as Map<String, dynamic>?;
    final gasOrderSite = gasOrder?['site'] as Map<String, dynamic>?;
    final siteJson = json['site'] as Map<String, dynamic>?;

    return DriverOrder(
      type: (json['type'] ?? '').toString(),
      id: _safeParseInt(json['id']),
      status: (json['status'] ?? '').toString(),
      orderType: json['order_type']?.toString(),
      requestCode: json['request_code']?.toString(),
      deliveryCode: json['delivery_code']?.toString(),
      site: siteJson != null
          ? DriverOrderSite.fromJson(siteJson)
          : gasOrderSite != null
              ? DriverOrderSite.fromJson(gasOrderSite)
              : null,
      supplier: json['supplier'] != null
          ? DriverOrderSupplier.fromJson(
              json['supplier'] as Map<String, dynamic>,
            )
          : null,
      bobtail: json['bobtail'] != null
          ? DriverOrderBobtail.fromJson(
              json['bobtail'] as Map<String, dynamic>,
            )
          : null,
      assignedDriverId: json['assigned_driver_id'] != null
          ? _safeParseInt(json['assigned_driver_id'])
          : null,
      unitCostPrice: json['unit_cost_price']?.toString(),
      productWeight: json['product_weight']?.toString(),
      actualKg: json['actual_kg']?.toString(),
      unitCost: json['unit_cost']?.toString(),
      requestCreatedAt: _parseDate(json['request_created_at']),
      deliveryDoneAt: _parseDate(json['delivery_done_at']),
      createdAt: _parseDate(json['created_at']),
    );
  }

  static int _safeParseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class DriverOrderSite {
  final int id;
  final String name;

  DriverOrderSite({
    required this.id,
    required this.name,
  });

  factory DriverOrderSite.fromJson(Map<String, dynamic> json) {
    return DriverOrderSite(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class DriverOrderSupplier {
  final int id;
  final String name;

  DriverOrderSupplier({
    required this.id,
    required this.name,
  });

  factory DriverOrderSupplier.fromJson(Map<String, dynamic> json) {
    return DriverOrderSupplier(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class DriverOrderBobtail {
  final int id;
  final String name;
  final int? serviceStationId;

  DriverOrderBobtail({
    required this.id,
    required this.name,
    this.serviceStationId,
  });

  factory DriverOrderBobtail.fromJson(Map<String, dynamic> json) {
    return DriverOrderBobtail(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      serviceStationId: json['service_station_id'] as int?,
    );
  }
}
