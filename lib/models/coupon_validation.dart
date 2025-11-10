class CouponValidationResult {
  final bool success;
  final String message;
  final CouponInfo? coupon;

  CouponValidationResult({
    required this.success,
    required this.message,
    required this.coupon,
  });

  factory CouponValidationResult.fromJson(Map<String, dynamic> json) {
    return CouponValidationResult(
      success: (json['success'] == true) || json['success']?.toString() == '1',
      message: json['message']?.toString() ?? '',
      coupon: json['coupon'] is Map<String, dynamic>
          ? CouponInfo.fromJson(json['coupon'] as Map<String, dynamic>)
          : null,
    );
  }
}

class CouponInfo {
  final int id;
  final String couponCode;
  final String status; // 'active', 'used', etc.
  final double liters; // parsed from string
  final DateTime expiresAt;
  final bool isExpired;
  final bool isValid;
  final ProductInfo product;
  final BatchInfo? batch;

  CouponInfo({
    required this.id,
    required this.couponCode,
    required this.status,
    required this.liters,
    required this.expiresAt,
    required this.isExpired,
    required this.isValid,
    required this.product,
    this.batch,
  });

  factory CouponInfo.fromJson(Map<String, dynamic> json) {
    final product = ProductInfo.fromJson(json['product'] as Map<String, dynamic>);
    final batch = json['batch'] is Map<String, dynamic>
        ? BatchInfo.fromJson(json['batch'] as Map<String, dynamic>)
        : null;
    return CouponInfo(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      couponCode: json['coupon_code']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      liters: double.tryParse(json['liters']?.toString() ?? '0') ?? 0,
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? '') ?? DateTime.now(),
      isExpired: json['is_expired'] == true,
      isValid: json['is_valid'] == true,
      product: product,
      batch: batch,
    );
  }
}

class ProductInfo {
  final int id;
  final String name;
  final String code;
  final double price; // parsed from string

  ProductInfo({
    required this.id,
    required this.name,
    required this.code,
    required this.price,
  });

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
    );
  }
}

class BatchInfo {
  final int id;
  final String batchCode;
  final CompanyInfo? company;

  BatchInfo({
    required this.id,
    required this.batchCode,
    this.company,
  });

  factory BatchInfo.fromJson(Map<String, dynamic> json) {
    return BatchInfo(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      batchCode: json['batch_code']?.toString() ?? '',
      company: json['company'] is Map<String, dynamic>
          ? CompanyInfo.fromJson(json['company'] as Map<String, dynamic>)
          : null,
    );
  }
}

class CompanyInfo {
  final int id;
  final String name;

  CompanyInfo({
    required this.id,
    required this.name,
  });

  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    return CompanyInfo(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}

