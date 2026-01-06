import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import '../models/product.dart';          // 🔹 product model
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../services/device_service.dart';
import '../utils/error_utils.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ProductService _productService = ProductService();
  final DeviceService _deviceService = DeviceService();
  
  // Device/session info (no auth flow)
  String? _serialNumber;
  String? _serviceStationId;
  String? _serviceStationName;
  String? _serviceStationAddress;
  String? _serviceStationPhone;
  bool _deviceActive = false;

  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;
  List<Product> _products = []; // 🔹 use typed model

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null && _token != null;
  List<Product> get products => _products;
  String? get serialNumber => _serialNumber;
  String? get serviceStationId => _serviceStationId;
  String? get serviceStationName => _serviceStationName;
  String? get serviceStationAddress => _serviceStationAddress;
  String? get serviceStationPhone => _serviceStationPhone;
  bool get isDeviceActive => _deviceActive ||
      (_serviceStationId != null && _serviceStationId!.isNotEmpty) ||
      (_currentUser != null && _currentUser!.serviceStationId > 0);

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Mobile login with username and operator code
  Future<bool> mobileLogin(String username, String operatorCode, String serialNumber) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _authService.mobileLogin(username, operatorCode, serialNumber);

      // Success - extract user and token (result is never null here, exceptions are thrown on failure)
      _currentUser = result!['user'] as User;
      _token = result['token'] as String;

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", _token!);
      await prefs.setString("user", _currentUser!.toJsonString());

      // Auto-save device session from user's service station info
      if (_currentUser!.serviceStationId > 0) {
        _serviceStationId = _currentUser!.serviceStationId.toString();
        _serviceStationName = _currentUser!.serviceStationName;
        _deviceActive = true;
        await prefs.setString('service_station_id', _serviceStationId!);
        await prefs.setString('service_station_name', _serviceStationName ?? '');
        await prefs.setBool('device_active', true);
      }

      // Fetch products right away
      await _fetchProducts();

      _setLoading(false);
      return true;
    } catch (e) {
      // Extract and display backend error message
      _setError(ErrorUtils.extractErrorMessage(e, fallback: 'Login failed'));
      _setLoading(false);
      return false;
    }
  }

  /// Legacy POS login (keeping for backward compatibility)
  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _authService.login(username, password);

      if (result != null) {
        _currentUser = result['user'] as User;
        _token = result['token'] as String;

        // Save to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", _token!);
        await prefs.setString("user", _currentUser!.toJsonString());

        // Auto-save device session from user's service station info
        if (_currentUser!.serviceStationId > 0) {
          _serviceStationId = _currentUser!.serviceStationId.toString();
          _serviceStationName = _currentUser!.serviceStationName;
          _deviceActive = true;
          await prefs.setString('service_station_id', _serviceStationId!);
          await prefs.setString('service_station_name', _serviceStationName ?? '');
          await prefs.setBool('device_active', true);
        }

        // Fetch products right away
        await _fetchProducts();

        _setLoading(false);
        return true;
      } else {
        _setError('Invalid credentials');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(ErrorUtils.extractErrorMessage(e, fallback: 'Login failed'));
      _setLoading(false);
      return false;
    }
  }


  Future<void> _fetchProducts() async {
    if (_token == null) {
      print("⚠️ Cannot fetch products: No token available");
      return;
    }

    try {
      print("📡 Fetching products with token...");
      final response = await _productService.fetchProducts(_token!);

      print("📡 RAW PRODUCTS RESPONSE: $response");

      final list = _extractProductList(response);
      if (list.isNotEmpty) {
        _products = list.map((p) => Product.fromJson(p as Map<String, dynamic>)).toList();
        print("✅ Products fetched successfully: ${_products.length}");
        notifyListeners();
      } else {
        print("⚠️ No products found in response");
        _products = [];
        notifyListeners();
      }
    } catch (e, stack) {
      print("🚨 Failed to fetch products: $e");
      print("📍 Stacktrace: $stack");
      _products = [];
      notifyListeners();
      // Don't silently fail - ensure notifyListeners is called so UI can update
    }
  }
  
  // New: Activate device by serial number
  Future<bool> launchDevice(String serialNumber) async {
    _setLoading(true);
    _setError(null);
    try {
      final resp = await _deviceService.launchDevice(serialNumber: serialNumber);
      // Expecting { status, message, data: { service_station_id, service_station_name, serial_number, ... } }
      final status = (resp['status'] ?? resp['success'])?.toString().toLowerCase();
      final isOk = status == 'success' || status == 'ok' || status == 'true' || status == '1';
      // Support both 'data' and 'device' payload shapes
      final data = (resp['data'] ?? resp['device']) as Map<String, dynamic>?;

      if (isOk) {
        if (data != null) {
          final stationId = (data['service_station_id'] ?? data['station_id'] ?? '').toString();
          final stationName = (data['service_station_name'] ?? data['station_name'] ?? '').toString();
          final stationAddress = (data['service_station_address'] ?? data['station_address'] ?? data['address'] ?? '').toString();
          final stationPhone = (data['service_station_phone'] ?? data['station_phone'] ?? data['phone'] ?? '').toString();
          final sn = (data['serial_number'] ?? serialNumber).toString();

          if (stationId.isNotEmpty) {
            print('[AuthProvider] Device launch: stationId=$stationId, stationName=$stationName');
            await saveDeviceSession(
              serialNumber: sn,
              serviceStationId: stationId,
              serviceStationName: stationName,
              serviceStationAddress: stationAddress,
              serviceStationPhone: stationPhone,
            );
          } else {
            print('[AuthProvider] Device launch success but station info missing in payload.');
          }
        }
        // Mark active even if API didn't return data block
        _deviceActive = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('device_active', true);
        notifyListeners();
        return true;
      }
      // Not successful -> surface message
      _setError(ErrorUtils.extractErrorMessage(resp, fallback: 'Device launch failed'));
      return false;
    } catch (e) {
      _setError(ErrorUtils.extractErrorMessage(e, fallback: 'Device launch failed'));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // New: fetch products by service station id without auth token
  Future<void> fetchProductsByStation() async {
    if (_serviceStationId == null) {
      print('[AuthProvider] Cannot fetch products: No service station ID');
      return;
    }
    try {
      _setLoading(true);
      // Logging request intent
      print('[AuthProvider] Fetching products for station: ${_serviceStationId!}');
      final response = await _productService.fetchProductsByStation(_serviceStationId!);

      // Normalize and extract products from various API shapes
      final list = _extractProductList(response);
      print('[AuthProvider] Normalized products count: ${list.length}');
      if (list.isNotEmpty) {
        _products = list.map((p) => Product.fromJson(p as Map<String, dynamic>)).toList();
        print('[AuthProvider] ✅ Products loaded: ${_products.length}');
      } else {
        print('[AuthProvider] ⚠️ No products found in response');
        _products = [];
      }
      notifyListeners();
    } catch (e, stack) {
      print('[AuthProvider] 🚨 Fetch products error: $e');
      print('[AuthProvider] Stack trace: $stack');
      _setError(ErrorUtils.extractErrorMessage(e, fallback: 'Failed to fetch products'));
      _products = [];
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Robust extractor for list of products from API responses
  List<dynamic> _extractProductList(dynamic response) {
    try {
      if (response == null) return const [];
      if (response is List) return response;
      if (response is Map<String, dynamic>) {
        final data = response['data'];
        // 1) data as List
        if (data is List) return data;
        // 2) data as Map with known list keys
        if (data is Map<String, dynamic>) {
          for (final key in const ['products', 'items', 'rows', 'result', 'list']) {
            final v = data[key];
            if (v is List) return v;
          }
        }
        // 3) top-level known list keys
        for (final key in const ['products', 'items', 'rows', 'result', 'list']) {
          final v = response[key];
          if (v is List) return v;
        }
      }
    } catch (e) {
      print('[AuthProvider] _extractProductList error: $e');
    }
    return const [];
  }

  /// Ensure products are loaded before navigating to sales flow.
  /// Tries by service station first; falls back to authenticated fetch.
  Future<void> ensureProductsLoaded({bool force = false}) async {
    if (!force && _products.isNotEmpty) return;
    await fetchLatestProducts();
  }

  /// Force fetch latest products from the best available source.
  /// Prefer token-based fetch when available for better security.
  Future<void> fetchLatestProducts() async {
    // Prioritize token-based fetch when user is logged in
    if (_token != null) {
      print('[AuthProvider] fetchLatestProducts: using token endpoint');
      await _fetchProducts();
      return;
    }
    // Fall back to station-based fetch if no token
    if (_serviceStationId != null && _serviceStationId!.isNotEmpty) {
      print('[AuthProvider] fetchLatestProducts: using station endpoint ($_serviceStationId)');
      await fetchProductsByStation();
      return;
    }
    print('[AuthProvider] fetchLatestProducts: no station or token available');
    // No way to fetch; clear list to be explicit
    _products = [];
    notifyListeners();
  }


  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout(_token);

      _currentUser = null;
      _token = null;
      _products = [];

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user');
    } catch (e) {
      _setError(ErrorUtils.extractErrorMessage(e, fallback: 'Logout failed'));
    } finally {
      _setLoading(false);
    }
  }

  /// Restore session on app start
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString("token");
    final savedUser = prefs.getString("user");
    _serialNumber = prefs.getString('serial_number');
    _serviceStationId = prefs.getString('service_station_id');
    _serviceStationName = prefs.getString('service_station_name');
    _serviceStationAddress = prefs.getString('service_station_address');
    _serviceStationPhone = prefs.getString('service_station_phone');
    _deviceActive = prefs.getBool('device_active') ?? false;

    if (savedToken != null && savedUser != null) {
      _token = savedToken;
      _currentUser = User.fromJsonString(savedUser);

      // 🔹 Auto-fetch products when restoring session
      await _fetchProducts();
    }
    // If device already active, preload products for station
    if (_serviceStationId != null) {
      await fetchProductsByStation();
    }
    notifyListeners();
  }


  Product? _selectedProduct;
  Product? get selectedProduct => _selectedProduct;

  void selectProduct(Product product) {
    _selectedProduct = product;
    notifyListeners();
  }

  // New: store device activation info
  Future<void> saveDeviceSession({
    required String serialNumber,
    required String serviceStationId,
    required String serviceStationName,
    String? serviceStationAddress,
    String? serviceStationPhone,
  }) async {
    _serialNumber = serialNumber;
    _serviceStationId = serviceStationId;
    _serviceStationName = serviceStationName;
    _serviceStationAddress = serviceStationAddress;
    _serviceStationPhone = serviceStationPhone;
    _deviceActive = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('serial_number', serialNumber);
    await prefs.setString('service_station_id', serviceStationId);
    await prefs.setString('service_station_name', serviceStationName);
    if ((serviceStationAddress ?? '').isNotEmpty) {
      await prefs.setString('service_station_address', serviceStationAddress!);
    }
    if ((serviceStationPhone ?? '').isNotEmpty) {
      await prefs.setString('service_station_phone', serviceStationPhone!);
    }
    await prefs.setBool('device_active', true);
    notifyListeners();
  }

  /// Reset operator code/password
  Future<bool> resetPassword({
    required String username,
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      print('[AuthProvider] Resetting operator code for: $username');

      final response = await _authService.resetOperatorCode(
        username: username,
        oldOperatorCode: oldPassword,
        newOperatorCode: newPassword,
        newOperatorCodeConfirmation: confirmPassword,
      );

      if (response['success'] == true) {
        print('[AuthProvider] ✅ Operator code reset successfully');
        return true;
      } else {
        final errorMessage = response['message'] ?? 'Password reset failed';
        print('[AuthProvider] ❌ Reset failed: $errorMessage');
        _setError(errorMessage);
        return false;
      }
    } catch (e) {
      print('[AuthProvider] 🚨 Reset password error: $e');
      _setError(ErrorUtils.extractErrorMessage(e, fallback: 'Password reset failed'));
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
