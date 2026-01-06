class Supplier {
  final int id;
  final String name;
  final String? description;
  final String? address;
  final String? city;
  final String? phoneNumber;
  final String? email;
  final String createdAt;
  final String updatedAt;

  Supplier({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.city,
    this.phoneNumber,
    this.email,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      phoneNumber: json['phone_number'] as String?,
      email: json['email'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'city': city,
      'phone_number': phoneNumber,
      'email': email,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
