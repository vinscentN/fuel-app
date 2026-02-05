import 'package:flutter/foundation.dart';
import '../models/buffalo_product.dart';
import '../models/buffalo_sale.dart';
import '../models/buffalo_balance.dart';
import '../models/buffalo_card_info.dart';
import '../services/buffalo_api_service.dart';

class BuffaloProvider with ChangeNotifier {
  List<BuffaloProduct> _products = [];
  bool _isLoadingProducts = false;
  String? _productsError;

  BuffaloCardInfo? _cardInfo;
  bool _isLoadingCardInfo = false;
  String? _cardInfoError;

  BuffaloSaleResponse? _lastSaleResponse;
  BuffaloBalanceResponse? _lastBalanceResponse;

  String? _cardNumber;

  // Getters
  List<BuffaloProduct> get products => _products;
  bool get isLoadingProducts => _isLoadingProducts;
  String? get productsError => _productsError;
  BuffaloCardInfo? get cardInfo => _cardInfo;
  bool get isLoadingCardInfo => _isLoadingCardInfo;
  String? get cardInfoError => _cardInfoError;
  BuffaloSaleResponse? get lastSaleResponse => _lastSaleResponse;
  BuffaloBalanceResponse? get lastBalanceResponse => _lastBalanceResponse;
  String? get cardNumber => _cardNumber;

  // Fetch products
  Future<void> fetchProducts() async {
    _isLoadingProducts = true;
    _productsError = null;
    notifyListeners();

    try {
      _products = await BuffaloApiService.fetchProducts();
      _isLoadingProducts = false;
      _productsError = null;
      notifyListeners();
    } catch (e) {
      _isLoadingProducts = false;
      _productsError = e.toString();
      notifyListeners();
    }
  }

  // Get card information
  Future<bool> getCardInfo(String cardNumber) async {
    _isLoadingCardInfo = true;
    _cardInfoError = null;
    _cardNumber = cardNumber;
    notifyListeners();

    try {
      final response = await BuffaloApiService.getCardInfo(cardNumber);

      if (response['success'] == true) {
        _cardInfo = response['data'] as BuffaloCardInfo;
        _isLoadingCardInfo = false;
        _cardInfoError = null;
        notifyListeners();
        return true;
      } else {
        _isLoadingCardInfo = false;
        _cardInfoError = response['message'] ?? 'Failed to get card info';
        _cardInfo = null;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoadingCardInfo = false;
      _cardInfoError = e.toString();
      _cardInfo = null;
      notifyListeners();
      return false;
    }
  }

  void setCardNumber(String cardNumber) {
    _cardNumber = cardNumber;
    notifyListeners();
  }

  void clearCardInfo() {
    _cardNumber = null;
    _cardInfo = null;
    _cardInfoError = null;
    notifyListeners();
  }

  // Submit sale
  Future<bool> submitSale({
    required String serialNumber,
    int? productId,
    int mealQuantity = 1,
  }) async {
    if (_cardNumber == null) {
      return false;
    }

    final resolvedProductId = productId ?? _cardInfo?.productId ?? 1;
    print(
      'DEBUG: submitSale resolved product_id=$resolvedProductId '
      '(arg=$productId, cardInfo=${_cardInfo?.productId})',
    );

    final saleRequest = BuffaloSaleRequest(
      cardNumber: _cardNumber!,
      serialNumber: serialNumber,
      productId: resolvedProductId,
      mealQuantity: mealQuantity,
    );

    try {
      _lastSaleResponse = await BuffaloApiService.submitSale(saleRequest);
      notifyListeners();
      return _lastSaleResponse!.success;
    } catch (e) {
      _lastSaleResponse = BuffaloSaleResponse(
        success: false,
        error: e.toString(),
      );
      notifyListeners();
      return false;
    }
  }

  // Check balance
  Future<bool> checkBalance(String cardNumber, {String? pin}) async {
    final balanceRequest = BuffaloBalanceRequest(
      cardNumber: cardNumber,
      pin: pin,
    );

    try {
      _lastBalanceResponse =
          await BuffaloApiService.checkBalance(balanceRequest);
      notifyListeners();
      return _lastBalanceResponse!.success;
    } catch (e) {
      _lastBalanceResponse = BuffaloBalanceResponse(
        success: false,
        error: e.toString(),
      );
      notifyListeners();
      return false;
    }
  }

  // Reset PIN
  Future<Map<String, dynamic>> resetPin({
    required String cardNumber,
    required String oldPin,
    required String newPin,
  }) async {
    return await BuffaloApiService.resetPin(
      cardNumber: cardNumber,
      oldPin: oldPin,
      newPin: newPin,
    );
  }

  // Reset state
  void resetTransaction() {
    clearCardInfo();
    _lastSaleResponse = null;
    notifyListeners();
  }
}
