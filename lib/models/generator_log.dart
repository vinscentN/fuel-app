class GeneratorLog {
  final int id;
  final DateTime startTime;
  final DateTime endTime;
  final String notes;
  final String createdBy;
  final DateTime createdAt;
  final int serviceStationId;
  final String? serviceStationName;

  GeneratorLog({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.notes,
    required this.createdBy,
    required this.createdAt,
    required this.serviceStationId,
    this.serviceStationName,
  });

  factory GeneratorLog.fromJson(Map<String, dynamic> json) {
    return GeneratorLog(
      id: json['id'] ?? 0,
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      notes: json['notes'] ?? '',
      createdBy: json['created_by'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      serviceStationId: json['service_station_id'] ?? 0,
      serviceStationName: json['service_station_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'service_station_id': serviceStationId,
      'service_station_name': serviceStationName,
    };
  }

  Duration get duration => endTime.difference(startTime);

  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }
}
