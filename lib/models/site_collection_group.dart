import 'site_collection.dart';

class SiteCollectionGroup {
  final String collectionReference;
  final int serviceStationId;
  final int? preparedByAttendantId;
  final int? completedByAttendantId;
  final String status;
  final DateTime? preparedAt;
  final DateTime? completedAt;
  final String? remarks;
  final int count;
  final List<SiteCollection> items;

  SiteCollectionGroup({
    required this.collectionReference,
    required this.serviceStationId,
    required this.preparedByAttendantId,
    required this.completedByAttendantId,
    required this.status,
    required this.preparedAt,
    required this.completedAt,
    required this.remarks,
    required this.count,
    required this.items,
  });

  factory SiteCollectionGroup.fromJson(Map<String, dynamic> json) {
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

    final items = (json['items'] as List<dynamic>?)
            ?.map((e) => SiteCollection.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return SiteCollectionGroup(
      collectionReference: json['collection_reference']?.toString() ?? '',
      serviceStationId: safeParseInt(json['service_station_id'], 0),
      preparedByAttendantId: safeParseInt(json['prepared_by_attendant_id'], 0),
      completedByAttendantId: safeParseInt(json['completed_by_attendant_id'], 0),
      status: json['status']?.toString() ?? 'PENDING',
      preparedAt: safeParseDate(json['prepared_at']),
      completedAt: safeParseDate(json['completed_at']),
      remarks: json['remarks']?.toString(),
      count: safeParseInt(json['count'], items.length),
      items: items,
    );
  }
}
