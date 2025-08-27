// providers/fuel_provider.dart
import 'package:flutter/material.dart';
import '../models/fuel_product.dart';
import '../models/currency.dart';
import '../services/fuel_service.dart';

class FuelProvider extends ChangeNotifier {
  final FuelService _fuelService = FuelService();

  List<FuelProduct> _products = [];
  List<Currency> _currencies = [];
  FuelProduct? _selectedProduct;
  Currency? _selectedCurrency;
  double _selectedAmount = 0.0;
  double _selectedQuantity = 0.0;
  bool _isLoading = false;

  List<FuelProduct> get products => _products;
  List<Currency> get currencies => _currencies;
  FuelProduct? get selectedProduct => _selectedProduct;
  Currency? get selectedCurrency => _selectedCurrency;
  double get selectedAmount => _selectedAmount;
  double get selectedQuantity => _selectedQuantity;
  bool get isLoading => _isLoading;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> loadProducts() async {
    _setLoading(true);
    try {
      _products = await _fuelService.getProducts();
    } catch (e) {
      debugPrint('Error loading products: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadCurrencies() async {
    try {
      _currencies = await _fuelService.getCurrencies();
      if (_currencies.isNotEmpty && _selectedCurrency == null) {
        _selectedCurrency = _currencies.first;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading currencies: $e');
    }
  }

  void selectProduct(FuelProduct product) {
    _selectedProduct = product;
    _selectedAmount = 0.0;
    _selectedQuantity = 0.0;
    notifyListeners();
  }

  void selectCurrency(Currency currency) {
    _selectedCurrency = currency;
    _selectedAmount = 0.0;
    _selectedQuantity = 0.0;
    notifyListeners();
  }

  void setAmount(double amount) {
    _selectedAmount = amount;
    if (_selectedProduct != null && _selectedCurrency != null) {
      final price = _selectedProduct!.prices[_selectedCurrency!.code] ?? 0.0;
      if (price > 0) {
        _selectedQuantity = amount / price;
      }
    }
    notifyListeners();
  }

  void setQuantity(double quantity) {
    _selectedQuantity = quantity;
    if (_selectedProduct != null && _selectedCurrency != null) {
      final price = _selectedProduct!.prices[_selectedCurrency!.code] ?? 0.0;
      _selectedAmount = quantity * price;
    }
    notifyListeners();
  }

  void reset() {
    _selectedProduct = null;
    _selectedAmount = 0.0;
    _selectedQuantity = 0.0;
    notifyListeners();
  }
}
