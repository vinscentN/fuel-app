class DeliveryOrder {
  final int id;
  final String orderType;
  final String status;
  final int? assignedDriverId;
  final String? assignedDriver;
  final String? expectedDeliveryDate;
  final String? expectedDeliveryTime;
  final bool hasBobtail;
  final double? expectedKg;
  final double? cylinderKg;
  final double? totalKg;
  final DeliveryCustomer? customer;
  final DeliveryLocation? location;
  final DeliverySite? site;
  final DeliveryBobtail? bobtail;
  final List<DeliveryOrderItem> items;
  final List<SwapCylinder> swapCylinders;
  final DeliveryBenchmark? benchmark;
  final String createdAt;
  final String? notes;

  DeliveryOrder({
    required this.id,
    required this.orderType,
    required this.status,
    this.assignedDriverId,
    this.assignedDriver,
    this.expectedDeliveryDate,
    this.expectedDeliveryTime,
    this.hasBobtail = false,
    this.expectedKg,
    this.cylinderKg,
    this.totalKg,
    this.customer,
    this.location,
    this.site,
    this.bobtail,
    required this.items,
    this.swapCylinders = const [],
    this.benchmark,
    required this.createdAt,
    this.notes,
  });

  factory DeliveryOrder.fromJson(Map<String, dynamic> json) {
    return DeliveryOrder(
      id: json['id'] ?? 0,
      orderType: json['order_type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      assignedDriverId: json['assigned_driver_id'],
      assignedDriver: json['assigned_driver']?.toString(),
      expectedDeliveryDate: json['expected_delivery_date']?.toString(),
      expectedDeliveryTime: json['expected_delivery_time']?.toString(),
      hasBobtail: json['has_bobtail'] == true,
      expectedKg: double.tryParse(json['expected_kg']?.toString() ?? ''),
      cylinderKg: double.tryParse(json['cylinder_kg']?.toString() ?? ''),
      totalKg: double.tryParse(json['total_kg']?.toString() ?? ''),
      customer: json['customer'] != null
          ? DeliveryCustomer.fromJson(json['customer'])
          : null,
      location: json['location'] != null
          ? DeliveryLocation.fromJson(json['location'])
          : null,
      site: json['site'] != null
          ? DeliverySite.fromJson(json['site'])
          : null,
      bobtail: json['bobtail'] != null
          ? DeliveryBobtail.fromJson(json['bobtail'])
          : null,
      items: (json['items'] as List<dynamic>?)
              ?.map((i) => DeliveryOrderItem.fromJson(i))
              .toList() ??
          [],
      swapCylinders: (json['swap_cylinders'] as List<dynamic>?)
              ?.map((i) => SwapCylinder.fromJson(i))
              .toList() ??
          [],
      benchmark: json['benchmark'] != null
          ? DeliveryBenchmark.fromJson(json['benchmark'])
          : null,
      createdAt: json['created_at']?.toString() ?? '',
      notes: json['notes']?.toString(),
    );
  }

  /// Readable label for the delivery type
  String get typeLabel {
    switch (orderType.toUpperCase()) {
      case 'DELIVERY_HOME':
        return 'HOME';
      case 'DELIVERY_COMMERCIAL':
        return 'COMMERCIAL';
      case 'DELIVERY_SITE':
        return 'RETAIL';
      default:
        return orderType;
    }
  }

  /// Recipient name (customer or site)
  String get recipientName => customer?.name ?? site?.name ?? 'Unknown';

  /// Delivery address — customer.address is the primary source
  String get deliveryAddress =>
      customer?.address ??
      location?.fullAddress ??
      site?.address ??
      site?.name ??
      'No address';

  /// Total number of cylinders
  int get cylinderCount => items.length;

  /// Total KGs loaded across all items
  double get totalKgsLoaded =>
      items.fold(0, (sum, item) => sum + (item.weights?.productWeight ?? item.quantity));

  /// Total value of all items
  double get totalValue => items.fold(0, (sum, item) => sum + item.total);
}

// ---------------------------------------------------------------------------

class DeliveryCustomer {
  final int id;
  final String name;
  final String? phone;
  final String? customerType;
  final String? address;

  DeliveryCustomer({
    required this.id,
    required this.name,
    this.phone,
    this.customerType,
    this.address,
  });

  factory DeliveryCustomer.fromJson(Map<String, dynamic> json) {
    return DeliveryCustomer(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      customerType: json['customer_type']?.toString(),
      address: json['address']?.toString(),
    );
  }
}

// ---------------------------------------------------------------------------

class DeliveryLocation {
  final int id;
  final String? label;
  final String? fullAddress;
  final String? latitude;
  final String? longitude;

  DeliveryLocation({
    required this.id,
    this.label,
    this.fullAddress,
    this.latitude,
    this.longitude,
  });

  factory DeliveryLocation.fromJson(Map<String, dynamic> json) {
    return DeliveryLocation(
      id: json['id'] ?? 0,
      label: json['label']?.toString(),
      fullAddress: json['full_address']?.toString(),
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
    );
  }
}

// ---------------------------------------------------------------------------

class DeliverySite {
  final int id;
  final String name;
  final String? address;

  DeliverySite({required this.id, required this.name, this.address});

  factory DeliverySite.fromJson(Map<String, dynamic> json) {
    return DeliverySite(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString(),
    );
  }
}

// ---------------------------------------------------------------------------

class DeliveryBobtail {
  final int id;
  final String name;
  final String? plateNumber;

  DeliveryBobtail({required this.id, required this.name, this.plateNumber});

  factory DeliveryBobtail.fromJson(Map<String, dynamic> json) {
    return DeliveryBobtail(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      plateNumber: json['plate_number']?.toString(),
    );
  }
}

// ---------------------------------------------------------------------------

class DeliveryOrderItem {
  final int id;
  final int productId;
  final double quantity;
  final double unitPrice;
  final double total;
  final String? serial;
  final String? cylinderName;
  final double? unitCostPrice;
  final String? invoiceNumber;
  final CylinderWeights? weights;
  final CylinderInfo? cylinder;
  final DeliveryProduct? product;

  DeliveryOrderItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.serial,
    this.cylinderName,
    this.unitCostPrice,
    this.invoiceNumber,
    this.weights,
    this.cylinder,
    this.product,
  });

  factory DeliveryOrderItem.fromJson(Map<String, dynamic> json) {
    return DeliveryOrderItem(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      quantity: double.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0,
      serial: json['serial']?.toString(),
      cylinderName: json['cylinder_name']?.toString(),
      unitCostPrice: double.tryParse(json['unit_cost_price']?.toString() ?? ''),
      invoiceNumber: json['invoice_number']?.toString(),
      weights: json['weights'] != null
          ? CylinderWeights.fromJson(json['weights'])
          : null,
      cylinder: json['cylinder'] != null
          ? CylinderInfo.fromJson(json['cylinder'])
          : null,
      product: json['product'] != null
          ? DeliveryProduct.fromJson(json['product'])
          : null,
    );
  }

  /// Tracking code — prefer cylinder.tracking_code, fallback to serial
  String get trackingCode {
    final tc = cylinder?.trackingCode;
    if (tc != null && tc.isNotEmpty) return tc;
    if (serial != null && serial!.isNotEmpty) return serial!;
    return 'N/A';
  }

  /// KGs loaded (product weight)
  double get kgsLoaded => weights?.productWeight ?? quantity;

  /// Current weight of cylinder
  double get currentWeight => weights?.currentWeight ?? 0;

  /// Bottom edge weight
  double get bottomEdgeWeight => weights?.bottomEdgeWeight ?? 0;
}

// ---------------------------------------------------------------------------

class CylinderWeights {
  final double? tareWeight;
  final double? bottomEdgeWeight;
  final double? manualBottomEdgeWeight;
  final double? calculatedBottomEdgeWeight;
  final double? beforeRefillWeight;
  final double? afterRefillWeight;
  final double? productWeight;
  final double? currentWeight;

  CylinderWeights({
    this.tareWeight,
    this.bottomEdgeWeight,
    this.manualBottomEdgeWeight,
    this.calculatedBottomEdgeWeight,
    this.beforeRefillWeight,
    this.afterRefillWeight,
    this.productWeight,
    this.currentWeight,
  });

  factory CylinderWeights.fromJson(Map<String, dynamic> json) {
    double? parse(dynamic v) =>
        v == null ? null : double.tryParse(v.toString());
    return CylinderWeights(
      tareWeight: parse(json['tare_weight']),
      bottomEdgeWeight: parse(json['bottom_edge_weight']),
      manualBottomEdgeWeight: parse(json['manual_bottom_edge_weight']),
      calculatedBottomEdgeWeight:
          parse(json['calculated_bottom_edge_weight']),
      beforeRefillWeight: parse(json['before_refill_weight']),
      afterRefillWeight: parse(json['after_refill_weight']),
      productWeight: parse(json['product_weight']),
      currentWeight: parse(json['current_weight']),
    );
  }
}

// ---------------------------------------------------------------------------

class CylinderInfo {
  final int id;
  final String name;
  final String trackingCode;
  final double? capacity;
  final String? unit;
  final double? maxProductWeight;
  final String? cylinderType;
  final String? product;

  CylinderInfo({
    required this.id,
    required this.name,
    required this.trackingCode,
    this.capacity,
    this.unit,
    this.maxProductWeight,
    this.cylinderType,
    this.product,
  });

  factory CylinderInfo.fromJson(Map<String, dynamic> json) {
    double? parse(dynamic v) =>
        v == null ? null : double.tryParse(v.toString());
    return CylinderInfo(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      trackingCode: json['tracking_code']?.toString() ?? json['serial']?.toString() ?? '',
      capacity: parse(json['capacity']),
      unit: json['unit']?.toString(),
      maxProductWeight: parse(json['max_product_weight']),
      cylinderType: json['cylinder_type']?.toString(),
      product: json['product']?.toString(),
    );
  }
}

// ---------------------------------------------------------------------------

class DeliveryProduct {
  final int id;
  final String name;
  final double price;

  DeliveryProduct({required this.id, required this.name, required this.price});

  factory DeliveryProduct.fromJson(Map<String, dynamic> json) {
    return DeliveryProduct(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
    );
  }
}

// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------

class SwapCylinder {
  final int assignmentId;
  final int cylinderId;
  final String serial;
  final String cylinderName;
  final String? assignedAt;
  final String status;       // e.g. "ASSIGNED" | "RETURNED"
  final String? returnedAt;

  SwapCylinder({
    required this.assignmentId,
    required this.cylinderId,
    required this.serial,
    required this.cylinderName,
    this.assignedAt,
    this.status = 'ASSIGNED',
    this.returnedAt,
  });

  bool get isReturned => status == 'RETURNED';

  factory SwapCylinder.fromJson(Map<String, dynamic> json) {
    return SwapCylinder(
      assignmentId: json['assignment_id'] ?? 0,
      cylinderId: json['cylinder_id'] ?? 0,
      serial: json['serial']?.toString() ?? '',
      cylinderName: json['cylinder_name']?.toString() ?? '',
      assignedAt: json['assigned_at']?.toString(),
      status: json['status']?.toString() ?? 'ASSIGNED',
      returnedAt: json['returned_at']?.toString(),
    );
  }
}

// ---------------------------------------------------------------------------

class DeliveryBenchmark {
  final int id;
  final String name;
  final String? latitude;
  final String? longitude;

  DeliveryBenchmark({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
  });

  factory DeliveryBenchmark.fromJson(Map<String, dynamic> json) {
    return DeliveryBenchmark(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
    );
  }
}
