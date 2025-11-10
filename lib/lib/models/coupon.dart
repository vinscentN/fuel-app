// models/coupon.dart
enum CouponType { percentage, fixed, fuelDiscount }
enum CouponStatus { active, used, expired, invalid }

class Coupon {
  final String id;
  final String code;
  final String title;
  final String description;
  final CouponType type;
  final double value;
  final String? applicableProductId;
  final DateTime expiryDate;
  final CouponStatus status;
  final double? minimumAmount;
  final double? maximumDiscount;

  Coupon({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.type,
    required this.value,
    required this.expiryDate,
    required this.status,
    this.applicableProductId,
    this.minimumAmount,
    this.maximumDiscount,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'],
      code: json['code'],
      title: json['title'],
      description: json['description'],
      type: CouponType.values.firstWhere(
            (e) => e.toString() == 'CouponType.${json['type']}',
      ),
      value: json['value'].toDouble(),
      expiryDate: DateTime.parse(json['expiryDate']),
      status: CouponStatus.values.firstWhere(
            (e) => e.toString() == 'CouponStatus.${json['status']}',
      ),
      applicableProductId: json['applicableProductId'],
      minimumAmount: json['minimumAmount']?.toDouble(),
      maximumDiscount: json['maximumDiscount']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'value': value,
      'expiryDate': expiryDate.toIso8601String(),
      'status': status.toString().split('.').last,
      'applicableProductId': applicableProductId,
      'minimumAmount': minimumAmount,
      'maximumDiscount': maximumDiscount,
    };
  }
}