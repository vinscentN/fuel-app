class WarehousePurchase {
  final int id;
  final String? description;
  final int? gasOrderId;
  final int? siteId;
  final int? attendantId;
  final int? supplierId;
  final String invoiceNumber;
  final String? invoiceFileUrl;
  final String quantity;
  final String quantityOut;
  final String quantityIn;
  final String unitPrice;
  final String status;
  final String createdAt;
  final String updatedAt;

  WarehousePurchase({
    required this.id,
    this.description,
    this.gasOrderId,
    this.siteId,
    this.attendantId,
    this.supplierId,
    required this.invoiceNumber,
    this.invoiceFileUrl,
    required this.quantity,
    required this.quantityOut,
    required this.quantityIn,
    required this.unitPrice,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WarehousePurchase.fromJson(Map<String, dynamic> json) {
    return WarehousePurchase(
      id: json['id'] as int,
      description: json['description'] as String?,
      gasOrderId: json['gas_order_id'] as int?,
      siteId: json['site_id'] as int?,
      attendantId: json['attendant_id'] as int?,
      supplierId: json['supplier_id'] as int?,
      invoiceNumber: json['invoice_number'] as String,
      invoiceFileUrl: json['invoice_file_url'] as String?,
      quantity: (json['quantity'] ?? 0).toString(),
      quantityOut: (json['quantity_out'] ?? 0).toString(),
      quantityIn: (json['quantity_in'] ?? 0).toString(),
      unitPrice: (json['unit_price'] ?? 0).toString(),
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'gas_order_id': gasOrderId,
      'site_id': siteId,
      'attendant_id': attendantId,
      'supplier_id': supplierId,
      'invoice_number': invoiceNumber,
      'invoice_file_url': invoiceFileUrl,
      'quantity': quantity,
      'quantity_out': quantityOut,
      'quantity_in': quantityIn,
      'unit_price': unitPrice,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  double get totalAmount {
    try {
      return double.parse(quantity) * double.parse(unitPrice);
    } catch (e) {
      return 0.0;
    }
  }
}
