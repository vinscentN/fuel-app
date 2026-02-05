class BuffaloSaleRequest {
  final String cardNumber;
  final String serialNumber;
  final int productId;
  final int? mealQuantity;

  BuffaloSaleRequest({
    required this.cardNumber,
    required this.serialNumber,
    required this.productId,
    this.mealQuantity,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'card_number': cardNumber,
      'serial_number': serialNumber,
      'product_id': productId,
    };

    if (mealQuantity != null) {
      json['meal_quantity'] = mealQuantity;
    }

    return json;
  }
}


class BuffaloSaleResponse {
  final bool success;
  final String? message;
  final SaleData? data;
  final String? error;

  BuffaloSaleResponse({
    required this.success,
    this.message,
    this.data,
    this.error,
  });

  factory BuffaloSaleResponse.fromJson(Map<String, dynamic> json) {
    return BuffaloSaleResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null ? SaleData.fromJson(json['data']) : null,
      error: json['error'],
    );
  }
}

class SaleData {
  final String? employeeName;
  final String? productName;
  final int? mealQuantity;
  final int? newMealBalance;
  final String? referenceNumber;
  final int? tapsRemainingToday;
  final String? timestamp;

  SaleData({
    this.employeeName,
    this.productName,
    this.mealQuantity,
    this.newMealBalance,
    this.referenceNumber,
    this.tapsRemainingToday,
    this.timestamp,
  });

  factory SaleData.fromJson(Map<String, dynamic> json) {
    return SaleData(
      employeeName: json['employee_name'],
      productName: json['product_name'],
      mealQuantity: json['meal_quantity'],
      newMealBalance: json['new_meal_balance'],
      referenceNumber: json['reference_number'],
      tapsRemainingToday: json['taps_remaining_today'],
      timestamp: json['timestamp'],
    );
  }
}

