import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/currency.dart';
import '../services/product_service.dart';

class FuelProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();

  List<Product> _products = [];
  List<Currency> _currencies = [];
  Product? _selectedProduct;
  Currency? _selectedCurrency;
  double _selectedAmount = 0.0;
  double _selectedQuantity = 0.0;
  bool _isLoading = false;

  // Getters
  List<Product> get products => _products;
  List<Currency> get currencies => _currencies;
  Product? get selectedProduct => _selectedProduct;
  Currency? get selectedCurrency => _selectedCurrency;
  double get selectedAmount => _selectedAmount;
  double get selectedQuantity => _selectedQuantity;
  bool get isLoading => _isLoading;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 🔹 Load products from API
  Future<void> loadProducts(String token) async {
    _setLoading(true);
    try {
      final response = await _productService.fetchProducts(token);
      debugPrint("📡 Raw products response: $response");

      if (response is Map<String, dynamic> && response['data'] is List) {
        final data = response['data'] as List<dynamic>;
        _products = data.map((p) => Product.fromJson(p)).toList();

        if (_products.isNotEmpty) {
          debugPrint("✅ Loaded ${_products.length} products. "
              "First: ${_products.first.productName} (${_products.first.id})");
        } else {
          debugPrint("⚠️ No products found in response.");
        }
      } else {
        debugPrint("⚠️ Unexpected response format: $response");
      }
    } catch (e, stack) {
      debugPrint("🚨 Error loading products: $e");
      debugPrint("📍 Stacktrace: $stack");
    } finally {
      _setLoading(false);
    }
  }

  /// 🔹 Load currencies (placeholder for now)
  Future<void> loadCurrencies() async {
    try {
      // TODO: Replace with actual API call
      _currencies = [];

      if (_currencies.isNotEmpty && _selectedCurrency == null) {
        _selectedCurrency = _currencies.first;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('🚨 Error loading currencies: $e');
    }
  }

  /// 🔹 Select product and reset amount/quantity
  void selectProduct(Product product) {
    _selectedProduct = product;
    _selectedAmount = 0.0;
    _selectedQuantity = 0.0;

    debugPrint("✅ Selected product: ${product.productName}, ID: ${product.id}");
    notifyListeners();
  }

  void selectCurrency(Currency currency) {
    _selectedCurrency = currency;
    _selectedAmount = 0.0;
    _selectedQuantity = 0.0;

    debugPrint("💱 Selected currency: ${currency.code}");
    notifyListeners();
  }

  void setAmount(double amount) {
    _selectedAmount = amount;
    if (_selectedProduct != null && _selectedProduct!.price > 0) {
      _selectedQuantity = amount / _selectedProduct!.price;
    }
    notifyListeners();
  }

  void setQuantity(double quantity) {
    _selectedQuantity = quantity;
    if (_selectedProduct != null) {
      _selectedAmount = quantity * _selectedProduct!.price;
    }
    notifyListeners();
  }

  void reset() {
    _selectedProduct = null;
    _selectedAmount = 0.0;
    _selectedQuantity = 0.0;
    debugPrint("🔄 FuelProvider reset called");
    notifyListeners();
  }
}