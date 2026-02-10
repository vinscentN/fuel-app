import 'gas_tank.dart';

class SiteCollection {
  final int id;
  final int serviceStationId;
  final int cylinderId;
  final int? preparedByAttendantId;
  final int? completedByAttendantId;
  final String currentWeight;
  final String tareWeight;
  final String bottomEdgeWeight;
  final String status;
  final DateTime? preparedAt;
  final DateTime? completedAt;
  final String? remarks;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final GasTank cylinder;

  SiteCollection({
    required this.id,
    required this.serviceStationId,
    required this.cylinderId,
    required this.preparedByAttendantId,
    required this.completedByAttendantId,
    required this.currentWeight,
    required this.tareWeight,
    required this.bottomEdgeWeight,
    required this.status,
    required this.preparedAt,
    required this.completedAt,
    required this.remarks,
    required this.createdAt,
    required this.updatedAt,
    required this.cylinder,
  });

  factory SiteCollection.fromJson(Map<String, dynamic> json) {
    int safeParseInt(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      try {
        return int.parse(value.toString());
      } catch (_) {
        return defaultValue;
      }
    }

    DateTime? safeParseDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    return SiteCollection(
      id: safeParseInt(json['id'], 0),
      serviceStationId: safeParseInt(json['service_station_id'], 0),
      cylinderId: safeParseInt(json['cylinder_id'], 0),
      preparedByAttendantId: safeParseInt(json['prepared_by_attendant_id'], 0),
      completedByAttendantId: safeParseInt(json['completed_by_attendant_id'], 0),
      currentWeight: json['current_weight']?.toString() ?? '0',
      tareWeight: json['tare_weight']?.toString() ?? '0',
      bottomEdgeWeight: json['bottom_edge_weight']?.toString() ?? '0',
      status: json['status']?.toString() ?? 'PENDING',
      preparedAt: safeParseDate(json['prepared_at']),
      completedAt: safeParseDate(json['completed_at']),
      remarks: json['remarks']?.toString(),
      createdAt: safeParseDate(json['created_at']),
      updatedAt: safeParseDate(json['updated_at']),
      cylinder: GasTank.fromJson((json['cylinder'] ?? {}) as Map<String, dynamic>),
    );
  }
}
