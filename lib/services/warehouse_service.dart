import '../constants/api_constants.dart';
import '../models/driver_order.dart';
import '../models/supplier.dart';
import '../models/warehouse_purchase.dart';
import 'api_client.dart';

class WarehouseService {
  final ApiClient _apiClient = ApiClient();

  /// Fetches list of suppliers
  Future<List<Supplier>> getSuppliers(String token) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/suppliers',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        return data.map((json) => Supplier.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('[WarehouseService] Error fetching suppliers: $e');
      rethrow;
    }
  }

  /// Fetches warehouse purchases with optional limit
  Future<Map<String, dynamic>> getWarehousePurchases({
    required String token,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/warehouse?limit=$limit',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        final List<WarehousePurchase> purchases =
            data.map((json) => WarehousePurchase.fromJson(json)).toList();

        // Parse balance - could be String, int, or double
        double balance = 0.0;
        if (response['balance'] != null) {
          if (response['balance'] is String) {
            balance = double.tryParse(response['balance']) ?? 0.0;
          } else if (response['balance'] is int) {
            balance = (response['balance'] as int).toDouble();
          } else if (response['balance'] is double) {
            balance = response['balance'];
          }
        }

        return {
          'success': true,
          'balance': balance,
          'purchases': purchases,
        };
      }

      return {
        'success': false,
        'balance': 0.0,
        'purchases': <WarehousePurchase>[],
      };
    } catch (e) {
      print('[WarehouseService] Error fetching warehouse purchases: $e');
      rethrow;
    }
  }

  /// Fetches driver orders for fulfillment
  Future<Map<String, dynamic>> getDriverOrders({
    required int driverId,
    required String token,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/driver-orders/$driverId',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        final List<DriverOrder> orders =
            data.map((json) => DriverOrder.fromJson(json)).toList();

        return {
          'success': true,
          'orders': orders,
          'driver': response['driver'],
        };
      }

      return {
        'success': false,
        'orders': <DriverOrder>[],
        'driver': response['driver'],
      };
    } catch (e) {
      print('[WarehouseService] Error fetching driver orders: $e');
      rethrow;
    }
  }

  /// Records a purchase from a driver order
  Future<Map<String, dynamic>> recordPurchaseFromOrder({
    required int orderId,
    required double quantity,
    required String invoiceNumber,
    required String token,
  }) async {
    try {
      final payload = {
        'order_id': orderId,
        'quantity': quantity,
        'invoice_number': invoiceNumber,
      };

      final response = await _apiClient.post(
        '${ApiConstants.baseUrl}/warehouse/purchases/from-order',
        body: payload,
        headers: {'Authorization': 'Bearer $token'},
      );

      return response;
    } catch (e) {
      print('[WarehouseService] Error recording purchase from order: $e');
      rethrow;
    }
  }

  /// Records a new supplier purchase
  Future<Map<String, dynamic>> recordPurchase({
    required String invoiceNumber,
    required int supplierId,
    required int attendantId,
    required double quantity,
    required double unitPrice,
    required String token,
  }) async {
    try {
      final payload = {
        'invoice_number': invoiceNumber,
        'supplier_id': supplierId,
        'attendant_id': attendantId,
        'quantity': quantity,
        'unit_price': unitPrice,
      };

      final response = await _apiClient.post(
        '${ApiConstants.baseUrl}/warehouse/purchases',
        body: payload,
        headers: {'Authorization': 'Bearer $token'},
      );

      return response;
    } catch (e) {
      print('[WarehouseService] Error recording purchase: $e');
      rethrow;
    }
  }
}
