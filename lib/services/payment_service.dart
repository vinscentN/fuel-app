// services/payment_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../models/customer.dart';
import '../constants/api_constants.dart';
import 'api_client.dart';
import 'pos_service.dart';

class PaymentService {
  final ApiClient _api = ApiClient();
  // Holds the last receipt payload returned by the API (response['data'])
  Map<String, dynamic>? lastReceiptData;

  Future<Transaction?> processPayment({
    required String userId,
    required String productId,
    required String currencyCode,
    required double amount,
    required double quantity,
    required PaymentMethod paymentMethod,
    String? mobileNumber,
    String? operatorPin,
    Map<String, dynamic>? cardDetails,
    String? couponCode,
    int? customerId,
    CustomerData? customerData,
  }) async {
    final url = '${ApiConstants.baseUrl}/sale';

    // Resolve serial number (prefer saved session, fallback to device read)
    final prefs = await SharedPreferences.getInstance();
    String? serial = prefs.getString('serial_number');
    serial ??= await PosService().readSerialNumber();

    // Map to API-required fields
    final payload = <String, dynamic>{
      // Required fields
      'attendant_id': int.tryParse(userId) ?? 0,
      'operator_code': int.tryParse((operatorPin ?? userId).toString()) ?? 0,
      'payment_method': paymentMethod.toString().split('.').last, // e.g. 'card', 'coupon'
      'serial_number': serial ?? '',
      'product_id': int.tryParse(productId) ?? productId,
      // Currency model doesn't expose id yet; default to 1 for now
      'currency_id': 1,
      'amount': amount,
      // Customer fields (optional)
      'customer_id': customerId,
      'customer': customerData?.toJson(),
      // Card details mapping for card payments
      if (paymentMethod == PaymentMethod.card)
        'card_pan': cardDetails?['cardNumber']?.toString() ?? '',
      if (paymentMethod == PaymentMethod.card)
        'pvv': (cardDetails?['pin'] ?? operatorPin)?.toString() ?? '',
      if (paymentMethod != PaymentMethod.card) 'card_pan': null,
      if (paymentMethod != PaymentMethod.card) 'pvv': null,
      // Coupon code for coupon payments
      if (paymentMethod == PaymentMethod.coupon)
        'coupon_code': couponCode ?? '',
    };

    final token = prefs.getString('token');
    final headers = <String, String>{
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final response = await _api.post(url, body: payload, headers: headers);

    // Persist receipt data for printing if present
    lastReceiptData = response['data'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(response['data'] as Map)
        : null;

    // Accept either { data: {...} } or a flat object for transaction mapping
    final obj = (response['data'] is Map<String, dynamic>)
        ? response['data'] as Map<String, dynamic>
        : response;

    return _mapToTransaction(
      obj,
      fallback: Transaction(
        id: (obj['id']?.toString() ?? 'TXN${DateTime.now().millisecondsSinceEpoch}'),
        userId: obj['userId']?.toString() ?? userId,
        productId: obj['productId']?.toString() ?? productId,
        currencyCode: obj['currencyCode']?.toString() ?? currencyCode,
        amount: _asDouble(obj['amount']) ?? amount,
        quantity: _asDouble(obj['quantity']) ?? quantity,
        paymentMethod: paymentMethod,
        status: _parseStatus(obj['status']) ?? TransactionStatus.completed,
        createdAt: _parseDate(obj['createdAt']) ?? DateTime.now(),
        // Try to map from receipt-ish fields too
        referenceNumber: obj['referenceNumber']?.toString() 
            ?? obj['reference']?.toString()
            ?? obj['authNo']?.toString(),
        mobileNumber: obj['mobileNumber']?.toString() ?? mobileNumber,
        operatorPin: obj['operatorPin']?.toString() ?? operatorPin,
      ),
    );
  }

  Transaction? _mapToTransaction(Map<String, dynamic> json, {required Transaction fallback}) {
    try {
      // If server already matches our model
      if (_looksLikeTransaction(json)) {
        return Transaction.fromJson(json);
      }
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  bool _looksLikeTransaction(Map<String, dynamic> json) {
    return json.containsKey('id') && json.containsKey('status');
  }

  double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
    }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  TransactionStatus? _parseStatus(dynamic v) {
    if (v == null) return null;
    final s = v.toString().toLowerCase();
    if (s.contains('complete')) return TransactionStatus.completed;
    if (s.contains('pending')) return TransactionStatus.pending;
    if (s.contains('cancel')) return TransactionStatus.cancelled;
    if (s.contains('fail') || s.contains('error')) return TransactionStatus.failed;
    return null;
  }
}
