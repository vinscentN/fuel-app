// models/transaction.dart
enum PaymentMethod { card, cash, mobile, coupon }
enum TransactionStatus { pending, completed, failed, cancelled }

class Transaction {
  final String id;
  final String userId;
  final String productId;
  final String currencyCode;
  final double amount;
  final double quantity;
  final PaymentMethod paymentMethod;
  final TransactionStatus status;
  final DateTime createdAt;
  final String? referenceNumber;
  final String? mobileNumber;
  final String? operatorPin;

  Transaction({
    required this.id,
    required this.userId,
    required this.productId,
    required this.currencyCode,
    required this.amount,
    required this.quantity,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.referenceNumber,
    this.mobileNumber,
    this.operatorPin,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      userId: json['userId'],
      productId: json['productId'],
      currencyCode: json['currencyCode'],
      amount: json['amount'].toDouble(),
      quantity: json['quantity'].toDouble(),
      paymentMethod: PaymentMethod.values.firstWhere(
            (e) => e.toString() == 'PaymentMethod.${json['paymentMethod']}',
      ),
      status: TransactionStatus.values.firstWhere(
            (e) => e.toString() == 'TransactionStatus.${json['status']}',
      ),
      createdAt: DateTime.parse(json['createdAt']),
      referenceNumber: json['referenceNumber'],
      mobileNumber: json['mobileNumber'],
      operatorPin: json['operatorPin'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'productId': productId,
      'currencyCode': currencyCode,
      'amount': amount,
      'quantity': quantity,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'referenceNumber': referenceNumber,
      'mobileNumber': mobileNumber,
      'operatorPin': operatorPin,
    };
  }
}
