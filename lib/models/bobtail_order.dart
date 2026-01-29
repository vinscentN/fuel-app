class BobtailOrder {
  final int id;
  final int bobtailId;
  final String orderType;
  final int? supplierId;
  final int? gasOrderId;
  final int? deliveryOrderId;
  final int assignedDriverId;
  final String expectedKg;
  final String? actualKg;
  final String? unitCost;
  final String status;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final BobtailInfo? bobtail;
  final SupplierInfo? supplier;
  final AssignedDriverInfo? assignedDriver;
  final GasOrderInfo? gasOrder;

  BobtailOrder({
    required this.id,
    required this.bobtailId,
    required this.orderType,
    this.supplierId,
    this.gasOrderId,
    this.deliveryOrderId,
    required this.assignedDriverId,
    required this.expectedKg,
    this.actualKg,
    this.unitCost,
    required this.status,
    this.notes,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.bobtail,
    this.supplier,
    this.assignedDriver,
    this.gasOrder,
  });

  factory BobtailOrder.fromJson(Map<String, dynamic> json) {
    return BobtailOrder(
      id: json['id'] ?? 0,
      bobtailId: json['bobtail_id'] ?? 0,
      orderType: (json['order_type'] ?? '').toString(),
      supplierId: json['supplier_id'] as int?,
      gasOrderId: json['gas_order_id'] as int?,
      deliveryOrderId: json['delivery_order_id'] as int?,
      assignedDriverId: json['assigned_driver_id'] ?? 0,
      expectedKg: (json['expected_kg'] ?? '0').toString(),
      actualKg: json['actual_kg']?.toString(),
      unitCost: json['unit_cost']?.toString(),
      status: (json['status'] ?? '').toString(),
      notes: json['notes']?.toString(),
      createdBy: json['created_by']?.toString(),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      bobtail: json['bobtail'] != null
          ? BobtailInfo.fromJson(json['bobtail'] as Map<String, dynamic>)
          : null,
      supplier: json['supplier'] != null
          ? SupplierInfo.fromJson(json['supplier'] as Map<String, dynamic>)
          : null,
      assignedDriver: json['assigned_driver'] != null
          ? AssignedDriverInfo.fromJson(
              json['assigned_driver'] as Map<String, dynamic>,
            )
          : null,
      gasOrder: json['gas_order'] != null
          ? GasOrderInfo.fromJson(json['gas_order'] as Map<String, dynamic>)
          : null,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    final parsed = DateTime.tryParse(value.toString());
    return parsed ?? DateTime.now();
  }
}

class BobtailInfo {
  final int id;
  final String name;
  final String? plateNumber;

  BobtailInfo({
    required this.id,
    required this.name,
    this.plateNumber,
  });

  factory BobtailInfo.fromJson(Map<String, dynamic> json) {
    return BobtailInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      plateNumber: json['plate_number']?.toString(),
    );
  }
}

class SupplierInfo {
  final int id;
  final String name;

  SupplierInfo({
    required this.id,
    required this.name,
  });

  factory SupplierInfo.fromJson(Map<String, dynamic> json) {
    return SupplierInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class AssignedDriverInfo {
  final int id;
  final String firstName;
  final String lastName;

  AssignedDriverInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  factory AssignedDriverInfo.fromJson(Map<String, dynamic> json) {
    return AssignedDriverInfo(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
    );
  }

  String get fullName => '$firstName $lastName'.trim();
}

class GasOrderInfo {
  final int id;
  final String requestCode;
  final int? siteId;
  final SiteInfo? site;

  GasOrderInfo({
    required this.id,
    required this.requestCode,
    this.siteId,
    this.site,
  });

  factory GasOrderInfo.fromJson(Map<String, dynamic> json) {
    return GasOrderInfo(
      id: json['id'] ?? 0,
      requestCode: json['request_code'] ?? '',
      siteId: json['site_id'] as int?,
      site: json['site'] != null
          ? SiteInfo.fromJson(json['site'] as Map<String, dynamic>)
          : null,
    );
  }
}

class SiteInfo {
  final int id;
  final String name;

  SiteInfo({
    required this.id,
    required this.name,
  });

  factory SiteInfo.fromJson(Map<String, dynamic> json) {
    return SiteInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}
