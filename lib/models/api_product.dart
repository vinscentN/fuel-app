class ApiProduct {
  final int id;
  final int productCategoryId;
  final String name;
  final String sku;
  final String? description;
  final String price;
  final int currencyId;
  final int stockQuantity;
  final int minimumStock;
  final String? image;
  final bool isActive;
  final bool isFeatured;
  final String createdAt;
  final String updatedAt;
  final Currency? currency;
  final ProductCategory? productCategory;

  ApiProduct({
    required this.id,
    required this.productCategoryId,
    required this.name,
    required this.sku,
    this.description,
    required this.price,
    required this.currencyId,
    required this.stockQuantity,
    required this.minimumStock,
    this.image,
    required this.isActive,
    required this.isFeatured,
    required this.createdAt,
    required this.updatedAt,
    this.currency,
    this.productCategory,
  });

  factory ApiProduct.fromJson(Map<String, dynamic> json) {
    return ApiProduct(
      id: json['id'] as int,
      productCategoryId: json['product_category_id'] as int,
      name: json['name'] as String,
      sku: json['sku'] as String,
      description: json['description'] as String?,
      price: (json['price'] ?? '0').toString(),
      currencyId: json['currency_id'] as int,
      stockQuantity: json['stock_quantity'] as int? ?? 0,
      minimumStock: json['minimum_stock'] as int? ?? 0,
      image: json['image'] as String?,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      isFeatured: json['is_featured'] == true || json['is_featured'] == 1,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      currency: json['currency'] != null
          ? Currency.fromJson(json['currency'] as Map<String, dynamic>)
          : null,
      productCategory: json['product_category'] != null
          ? ProductCategory.fromJson(json['product_category'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_category_id': productCategoryId,
      'name': name,
      'sku': sku,
      'description': description,
      'price': price,
      'currency_id': currencyId,
      'stock_quantity': stockQuantity,
      'minimum_stock': minimumStock,
      'image': image,
      'is_active': isActive,
      'is_featured': isFeatured,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'currency': currency?.toJson(),
      'product_category': productCategory?.toJson(),
    };
  }

  double get priceValue => double.tryParse(price) ?? 0.0;
}

class Currency {
  final int id;
  final String code;
  final String symbol;

  Currency({
    required this.id,
    required this.code,
    required this.symbol,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      id: json['id'] as int,
      code: json['code'] as String,
      symbol: json['symbol'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'symbol': symbol,
    };
  }
}

class ProductCategory {
  final int id;
  final String name;

  ProductCategory({
    required this.id,
    required this.name,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

// Product purchase request
class ProductPurchaseRequest {
  final int productId;
  final int quantity;
  final String? cardNumber;
  final int? userId;
  final String paymentMethod; // 'card', 'cash', 'mobile'

  ProductPurchaseRequest({
    required this.productId,
    required this.quantity,
    this.cardNumber,
    this.userId,
    required this.paymentMethod,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'product_id': productId,
      'quantity': quantity,
      'payment_method': paymentMethod,
    };

    if (cardNumber != null) {
      json['card_number'] = cardNumber;
    }
    if (userId != null) {
      json['user_id'] = userId;
    }

    return json;
  }
}

// Product purchase response
class ProductPurchaseResponse {
  final bool success;
  final String? message;
  final PurchaseTransaction? transaction;
  final PurchaseProduct? product;
  final String? balance;

  ProductPurchaseResponse({
    required this.success,
    this.message,
    this.transaction,
    this.product,
    this.balance,
  });

  factory ProductPurchaseResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return ProductPurchaseResponse(
      success: json['status'] == 'success',
      message: json['message'],
      transaction: data != null && data['transaction'] != null
          ? PurchaseTransaction.fromJson(data['transaction'])
          : null,
      product: data != null && data['product'] != null
          ? PurchaseProduct.fromJson(data['product'])
          : null,
      balance: data != null ? data['balance']?.toString() : null,
    );
  }
}

class PurchaseTransaction {
  final int id;
  final String transactionNumber;
  final int? membershipCardId;
  final int? userId;
  final String type;
  final String amount;
  final int currencyId;
  final String? balanceBefore;
  final String? balanceAfter;
  final String status;

  PurchaseTransaction({
    required this.id,
    required this.transactionNumber,
    this.membershipCardId,
    this.userId,
    required this.type,
    required this.amount,
    required this.currencyId,
    this.balanceBefore,
    this.balanceAfter,
    required this.status,
  });

  factory PurchaseTransaction.fromJson(Map<String, dynamic> json) {
    return PurchaseTransaction(
      id: json['id'],
      transactionNumber: json['transaction_number'],
      membershipCardId: json['membership_card_id'],
      userId: json['user_id'],
      type: json['type'],
      amount: json['amount'].toString(),
      currencyId: json['currency_id'],
      balanceBefore: json['balance_before']?.toString(),
      balanceAfter: json['balance_after']?.toString(),
      status: json['status'],
    );
  }
}

class PurchaseProduct {
  final int id;
  final String name;
  final String price;
  final int stockQuantity;

  PurchaseProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.stockQuantity,
  });

  factory PurchaseProduct.fromJson(Map<String, dynamic> json) {
    return PurchaseProduct(
      id: json['id'],
      name: json['name'],
      price: json['price'].toString(),
      stockQuantity: json['stock_quantity'],
    );
  }
}
