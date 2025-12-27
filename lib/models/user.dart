import 'dart:convert';

class User {
  final int id;
  final String name;
  final String username;
  final String designation;
  final int serviceStationId;
  final String serviceStationName;
  final int? checkInId;
  final String? checkInTime;
  final String? checkInDate;

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.designation,
    required this.serviceStationId,
    required this.serviceStationName,
    this.checkInId,
    this.checkInTime,
    this.checkInDate,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle both old format and new mobile login format
    final attendantData = json['attendant'] ?? json;
    final serviceStation = attendantData['service_station'] ?? {};
    final checkIn = json['check_in'];

    return User(
      id: (attendantData['id'] ?? json['id']).toString().isEmpty
          ? 0
          : int.parse((attendantData['id'] ?? json['id']).toString()),
      name: attendantData['name'] ??
            '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
      username: attendantData['username'] ?? json['username'] ?? '',
      designation: attendantData['designation'] ?? json['designation'] ?? 'ATTENDANT',
      serviceStationId: serviceStation['id'] ??
                        attendantData['service_station_id'] ??
                        json['service_station_id'] ??
                        0,
      serviceStationName: serviceStation['name'] ??
                          attendantData['service_station_name'] ??
                          json['service_station_name'] ??
                          '',
      checkInId: checkIn?['id'],
      checkInTime: checkIn?['time'],
      checkInDate: checkIn?['date'],
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "username": username,
    "designation": designation,
    "service_station_id": serviceStationId,
    "service_station_name": serviceStationName,
    if (checkInId != null) "check_in_id": checkInId,
    if (checkInTime != null) "check_in_time": checkInTime,
    if (checkInDate != null) "check_in_date": checkInDate,
  };

  String toJsonString() => jsonEncode(toJson());
  factory User.fromJsonString(String jsonStr) =>
      User.fromJson(jsonDecode(jsonStr));

  String get fullName => name;

  bool get isAttendant => designation.toUpperCase() == 'ATTENDANT';
  bool get isDriver => designation.toUpperCase() == 'DRIVER';
}
