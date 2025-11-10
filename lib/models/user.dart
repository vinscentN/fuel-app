import 'dart:convert';

class User {
  final String id;
  final String firstName;
  final String lastName;
  final int serviceStationId;
  final String serviceStationName;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.serviceStationId,
    required this.serviceStationName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      firstName: json['first_name'],
      lastName: json['last_name'],
      serviceStationId: json['service_station_id'],
      serviceStationName: json['service_station_name'],
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "first_name": firstName,
    "last_name": lastName,
    "service_station_id": serviceStationId,
    "service_station_name": serviceStationName,
  };

  String toJsonString() => jsonEncode(toJson());
  factory User.fromJsonString(String jsonStr) =>
      User.fromJson(jsonDecode(jsonStr));

  String get fullName => "$firstName $lastName";
}
