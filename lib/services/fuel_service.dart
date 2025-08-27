// services/fuel_service.dart
import '../models/fuel_product.dart';
import '../models/currency.dart';

class FuelService {
  // Dummy fuel products data
  static const List<Map<String, dynamic>> _dummyProducts = [
    {
      'id': '1',
      'name': 'Petrol Blend',
      'type': 'petrol',
      'description': '',
      'iconPath': 'assets/images/petrol_icon.png',
      'prices': {'USD': 1.35, 'ZWL': 2450.00},
      'isAvailable': true,
    },
    {
      'id': '2',
      'name': 'Diesel',
      'type': 'diesel',
      'description': '',
      'iconPath': 'assets/images/diesel_icon.png',
      'prices': {'USD': 1.28, 'ZWL': 2320.00},
      'isAvailable': true,
    }

  ];

  // Dummy currency data
  static const List<Map<String, dynamic>> _dummyCurrencies = [
    {
      'code': 'USD',
      'name': 'US Dollar',
      'symbol': '\$',
      'exchangeRate': 1.0,
      'isActive': true,
    },
    {
      'code': 'ZWL',
      'name': 'Zimbabwean Dollar',
      'symbol': 'ZWL\$',
      'exchangeRate': 1815.5,
      'isActive': true,
    },
  ];

  Future<List<FuelProduct>> getProducts() async {
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 800));

    return _dummyProducts
        .map((product) => FuelProduct.fromJson(product))
        .toList();
  }

  Future<List<Currency>> getCurrencies() async {
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));

    return _dummyCurrencies
        .map((currency) => Currency.fromJson(currency))
        .toList();
  }

  // API endpoint placeholders for future implementation
  static const String productsEndpoint = '/api/fuel/products';
  static const String currenciesEndpoint = '/api/fuel/currencies';
  static const String pricesEndpoint = '/api/fuel/prices';
}