// providers/payment_provider.dart
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _paymentService = PaymentService();

  PaymentMethod? _selectedPaymentMethod;
  bool _isProcessing = false;
  String? _errorMessage;
  Transaction? _currentTransaction;

  PaymentMethod? get selectedPaymentMethod => _selectedPaymentMethod;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  Transaction? get currentTransaction => _currentTransaction;

  void selectPaymentMethod(PaymentMethod method) {
    _selectedPaymentMethod = method;
    _errorMessage = null;
    notifyListeners();
  }

  void _setProcessing(bool processing) {
    _isProcessing = processing;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  Future<bool> processPayment({
    required String userId,
    required String productId,
    required String currencyCode,
    required double amount,
    required double quantity,
    required PaymentMethod paymentMethod,
    String? mobileNumber,
    String? operatorPin,
    Map<String, dynamic>? cardDetails,
  }) async {
    _setProcessing(true);
    _setError(null);

    try {
      final transaction = await _paymentService.processPayment(
        userId: userId,
        productId: productId,
        currencyCode: currencyCode,
        amount: amount,
        quantity: quantity,
        paymentMethod: paymentMethod,
        mobileNumber: mobileNumber,
        operatorPin: operatorPin,
        cardDetails: cardDetails,
      );

      if (transaction != null) {
        _currentTransaction = transaction;
        _setProcessing(false);
        return true;
      } else {
        _setError('Payment processing failed');
        _setProcessing(false);
        return false;
      }
    } catch (e) {
      _setError('Payment failed: ${e.toString()}');
      _setProcessing(false);
      return false;
    }
  }

  void reset() {
    _selectedPaymentMethod = null;
    _currentTransaction = null;
    _errorMessage = null;
    notifyListeners();
  }
}
