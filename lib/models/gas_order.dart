import 'gas_tank.dart';

class GasOrder {
  final int id;
  final String requestCode;
  final String? deliveryCode;
  final String totalManualBottomEdgeWeight;
  final String totalCalculatedBottomEdgeWeight;
  final String productWeight;
  final String description;
  final String status;
  final String requestCreatedBy;
  final String? deliveryDoneBy;
  final DateTime requestCreatedAt;
  final DateTime? deliveryDoneAt;
  final String? invoiceNumber;
  final int siteId;
  final ServiceStation site;
  final List<GasOrderItem> items;

  GasOrder({
    required this.id,
    required this.requestCode,
    this.deliveryCode,
    required this.totalManualBottomEdgeWeight,
    required this.totalCalculatedBottomEdgeWeight,
    required this.productWeight,
    required this.description,
    required this.status,
    required this.requestCreatedBy,
    this.deliveryDoneBy,
    required this.requestCreatedAt,
    this.deliveryDoneAt,
    this.invoiceNumber,
    required this.siteId,
    required this.site,
    required this.items,
  });

  factory GasOrder.fromJson(Map<String, dynamic> json) {
    return GasOrder(
      id: json['id'] ?? 0,
      requestCode: json['request_code'] ?? '',
      deliveryCode: json['delivery_code'],
      totalManualBottomEdgeWeight: json['total_manual_bottom_edge_weight'] ?? '0',
      totalCalculatedBottomEdgeWeight: json['total_calculated_bottom_edge_weight'] ?? '0',
      productWeight: json['product_weight'] ?? '0',
      description: json['description'] ?? '',
      status: json['status'] ?? '',
      requestCreatedBy: json['request_created_by'] ?? '',
      deliveryDoneBy: json['delivery_done_by'],
      requestCreatedAt: DateTime.parse(json['request_created_at']),
      deliveryDoneAt: json['delivery_done_at'] != null
          ? DateTime.parse(json['delivery_done_at'])
          : null,
      invoiceNumber: json['invoice_number'],
      siteId: json['site_id'] ?? 0,
      site: ServiceStation.fromJson(json['site'] ?? {}),
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => GasOrderItem.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_code': requestCode,
      'delivery_code': deliveryCode,
      'total_manual_bottom_edge_weight': totalManualBottomEdgeWeight,
      'total_calculated_bottom_edge_weight': totalCalculatedBottomEdgeWeight,
      'product_weight': productWeight,
      'description': description,
      'status': status,
      'request_created_by': requestCreatedBy,
      'delivery_done_by': deliveryDoneBy,
      'request_created_at': requestCreatedAt.toIso8601String(),
      'delivery_done_at': deliveryDoneAt?.toIso8601String(),
      'invoice_number': invoiceNumber,
      'site_id': siteId,
      'site': site.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class GasOrderItem {
  final int id;
  final int gasOrderId;
  final int gasTankId;
  final String manualBottomEdgeWeight;
  final String calculatedBottomEdgeWeight;
  final String beforeRefillWeight;
  final String afterRefillWeight;
  final GasTank gasTank;

  GasOrderItem({
    required this.id,
    required this.gasOrderId,
    required this.gasTankId,
    required this.manualBottomEdgeWeight,
    required this.calculatedBottomEdgeWeight,
    required this.beforeRefillWeight,
    required this.afterRefillWeight,
    required this.gasTank,
  });

  factory GasOrderItem.fromJson(Map<String, dynamic> json) {
    int safeParseInt(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      try {
        return int.parse(value.toString());
      } catch (e) {
        return defaultValue;
      }
    }

    final gasTankJson = json['gas_tank'] ?? json['cylinder'];
    final fallbackGasTankId = gasTankJson is Map
        ? safeParseInt(gasTankJson['id'], 0)
        : 0;
    final parsedGasTankId = safeParseInt(json['gas_tank_id'], 0);
    final parsedCylinderId = safeParseInt(json['cylinder_id'], 0);
    final parsedTankId = safeParseInt(json['tank_id'], 0);
    final resolvedGasTankId = parsedGasTankId != 0
        ? parsedGasTankId
        : parsedCylinderId != 0
            ? parsedCylinderId
            : parsedTankId != 0
                ? parsedTankId
                : fallbackGasTankId;

    return GasOrderItem(
      id: json['id'] ?? 0,
      gasOrderId: json['gas_order_id'] ?? 0,
      gasTankId: resolvedGasTankId,
      manualBottomEdgeWeight: json['manual_bottom_edge_weight'] ?? '0',
      calculatedBottomEdgeWeight: json['calculated_bottom_edge_weight'] ?? '0',
      beforeRefillWeight: json['before_refill_weight'] ?? '0',
      afterRefillWeight: json['after_refill_weight'] ?? '0',
      gasTank: GasTank.fromJson(gasTankJson ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gas_order_id': gasOrderId,
      'cylinder_id': gasTankId,
      'manual_bottom_edge_weight': manualBottomEdgeWeight,
      'calculated_bottom_edge_weight': calculatedBottomEdgeWeight,
      'before_refill_weight': beforeRefillWeight,
      'after_refill_weight': afterRefillWeight,
      'gas_tank': gasTank.toJson(),
    };
  }
}

class PendingGasOrder {
  final int id;
  final String requestCode;
  final String? deliveryCode;
  final String status;
  final String description;
  final String createdBy;
  final DateTime createdAt;
  final ServiceStation site;
  final int tanksCount;
  final List<TankPreview> itemsPreview;

  PendingGasOrder({
    required this.id,
    required this.requestCode,
    this.deliveryCode,
    required this.status,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    required this.site,
    required this.tanksCount,
    required this.itemsPreview,
  });

  factory PendingGasOrder.fromJson(Map<String, dynamic> json) {
    return PendingGasOrder(
      id: json['id'] ?? 0,
      requestCode: json['request_code'] ?? '',
      deliveryCode: json['delivery_code'],
      status: json['status'] ?? '',
      description: json['description'] ?? '',
      createdBy: json['created_by'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      site: ServiceStation.fromJson(json['site'] ?? {}),
      tanksCount: json['tanks_count'] ?? 0,
      itemsPreview: (json['items_preview'] as List<dynamic>?)
          ?.map((item) => TankPreview.fromJson(item))
          .toList() ?? [],
    );
  }
}

class TankPreview {
  final int itemId;
  final int tankId;
  final String tankName;
  final String trackingCode;
  final String cylinderType;
  final String capacity;
  final String bottomWeight;

  TankPreview({
    required this.itemId,
    required this.tankId,
    required this.tankName,
    required this.trackingCode,
    required this.cylinderType,
    required this.capacity,
    required this.bottomWeight,
  });

  factory TankPreview.fromJson(Map<String, dynamic> json) {
    return TankPreview(
      itemId: json['item_id'] ?? 0,
      tankId: json['tank_id'] ?? 0,
      tankName: json['tank_name'] ?? '',
      trackingCode: json['tracking_code'] ?? '',
      cylinderType: json['cylinder_type'] ?? '',
      capacity: json['capacity'] ?? '0',
      bottomWeight: json['bottom_weight'] ?? '0',
    );
  }
}

class ServiceStation {
  final int id;
  final String name;
  final String? stationCode;
  final String? status;
  final String? address;
  final String? city;

  ServiceStation({
    required this.id,
    required this.name,
    this.stationCode,
    this.status,
    this.address,
    this.city,
  });

  factory ServiceStation.fromJson(Map<String, dynamic> json) {
    return ServiceStation(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      stationCode: json['station_code'],
      status: json['status'],
      address: json['address'],
      city: json['city'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'station_code': stationCode,
      'status': status,
      'address': address,
      'city': city,
    };
  }
}
