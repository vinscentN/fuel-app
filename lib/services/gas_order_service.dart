import '../constants/api_constants.dart';
import '../models/gas_tank.dart';
import '../models/gas_order.dart';
import 'api_client.dart';

class GasOrderService {
  final ApiClient _apiClient = ApiClient();

  /// Fetches gas tanks/cylinders for a specific service station
  Future<List<GasTank>> getTanksForStation(int serviceStationId, String token) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/gas-orders/sites/$serviceStationId/tanks',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        return data.map((json) => GasTank.fromJson(json)).toList();
      }

      throw Exception('Failed to load tanks');
    } catch (e) {
      print('[GasOrderService] Error fetching tanks: $e');
      rethrow;
    }
  }

  /// Creates a new fill request
  Future<Map<String, dynamic>> createFillRequest({
    required int siteId,
    required String description,
    required String createdBy,
    required List<Map<String, dynamic>> tanks,
    required String token,
  }) async {
    try {
      final payload = {
        'site_id': siteId,
        'description': description,
        'created_by': createdBy,
        'tanks': tanks,
      };

      final response = await _apiClient.post(
        '${ApiConstants.baseUrl}/gas-orders/create-request',
        body: payload,
        headers: {'Authorization': 'Bearer $token'},
      );

      return response;
    } catch (e) {
      print('[GasOrderService] Error creating fill request: $e');
      rethrow;
    }
  }

  /// Updates a pending request with cylinders
  Future<Map<String, dynamic>> updatePendingRequestCylinders({
    required int orderId,
    required String description,
    required List<Map<String, dynamic>> tanks,
    required String token,
  }) async {
    try {
      final payload = {
        'description': description,
        'tanks': tanks,
      };

      final response = await _apiClient.put(
        '${ApiConstants.baseUrl}/gas-orders/$orderId/update',
        body: payload,
        headers: {'Authorization': 'Bearer $token'},
      );

      return response;
    } catch (e) {
      print('[GasOrderService] Error updating pending request cylinders: $e');
      rethrow;
    }
  }

  /// Fetches pending gas orders for a specific site
  Future<List<PendingGasOrder>> getPendingOrders(int siteId, String token) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/gas-orders/pending/$siteId',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        return data.map((json) => PendingGasOrder.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('[GasOrderService] Error fetching pending orders: $e');
      rethrow;
    }
  }

  /// Fetches pending gas orders for drivers (no site id in endpoint)
  Future<List<PendingGasOrder>> getPendingOrdersForDriver(String token) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/gas-orders/pending',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        return data.map((json) => PendingGasOrder.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('[GasOrderService] Error fetching pending orders (driver): $e');
      rethrow;
    }
  }

  /// Fetches picked-up gas orders for a specific site (for delivery creation)
  Future<List<PendingGasOrder>> getPickedUpOrders(int siteId, String token) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/gas-orders/picked-up/$siteId',
        headers: {'Authorization': 'Bearer $token'},
      );

      // Check for both 'success' and 'status' fields
      final isSuccess = response['success'] == true ||
                       response['status'] == 'success' ||
                       response['code'] == 200;

      if (isSuccess && response['data'] != null) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        return data.map((json) => PendingGasOrder.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('[GasOrderService] Error fetching picked-up orders: $e');
      rethrow;
    }
  }

  /// Fetches pending deliveries
  Future<List<PendingGasOrder>> getPendingDeliveries(String token) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/gas-orders/pending-deliveries',
        headers: {'Authorization': 'Bearer $token'},
      );

      // Check for both 'success' and 'status' fields
      final isSuccess = response['success'] == true ||
                       response['status'] == 'success' ||
                       response['code'] == 200;

      if (isSuccess && response['data'] != null) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        return data.map((json) => PendingGasOrder.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('[GasOrderService] Error fetching pending deliveries: $e');
      rethrow;
    }
  }

  /// Fetches detailed gas order information by request code
  Future<GasOrder> getOrderByRequestCode(String requestCode, String token) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/gas-orders/request-code/$requestCode',
        headers: {'Authorization': 'Bearer $token'},
      );

      return GasOrder.fromJson(response);
    } catch (e) {
      print('[GasOrderService] Error fetching order details: $e');
      rethrow;
    }
  }

  /// Confirms pickup of a gas order
  Future<Map<String, dynamic>> confirmPickup({
    required String requestCode,
    required int driverAttendantId,
    required String token,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.baseUrl}/gas-orders/pickup/$requestCode',
        body: {
          'driver_attendant_id': driverAttendantId,
        },
        headers: {'Authorization': 'Bearer $token'},
      );

      return response;
    } catch (e) {
      print('[GasOrderService] Error confirming pickup: $e');
      rethrow;
    }
  }

  /// Fetches list of service stations/sites
  Future<List<ServiceStation>> getSites(String token) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/sites',
        headers: {'Authorization': 'Bearer $token'},
      );

      // Check for both 'success' and 'status' fields
      final isSuccess = response['success'] == true ||
                       response['status'] == 'success' ||
                       response['code'] == 200;

      if (isSuccess && response['data'] != null) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        return data.map((json) => ServiceStation.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('[GasOrderService] Error fetching sites: $e');
      rethrow;
    }
  }

  /// Creates a delivery order
  Future<Map<String, dynamic>> createDelivery({
    required int orderId,
    required int driverAttendantId,
    required String invoiceNumber,
    required List<Map<String, dynamic>> tanks,
    required String token,
  }) async {
    try {
      final payload = {
        'driver_attendant_id': driverAttendantId,
        'invoice_number': invoiceNumber,
        'tanks': tanks,
      };

      final response = await _apiClient.post(
        '${ApiConstants.baseUrl}/gas-orders/$orderId/create-delivery',
        body: payload,
        headers: {'Authorization': 'Bearer $token'},
      );

      return response;
    } catch (e) {
      print('[GasOrderService] Error creating delivery: $e');
      rethrow;
    }
  }

  /// Fetches delivery details by delivery code
  Future<GasOrder> getOrderByDeliveryCode(String deliveryCode, String token) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/gas-orders/delivery-code/$deliveryCode',
        headers: {'Authorization': 'Bearer $token'},
      );

      return GasOrder.fromJson(response);
    } catch (e) {
      print('[GasOrderService] Error fetching delivery details: $e');
      rethrow;
    }
  }

  /// Receives a delivery
  Future<Map<String, dynamic>> receiveDelivery({
    required String deliveryCode,
    required int receivedByAttendantId,
    required List<Map<String, dynamic>> tanks,
    required String token,
  }) async {
    try {
      final payload = {
        'received_by_attendant_id': receivedByAttendantId,
        'tanks': tanks,
      };

      final response = await _apiClient.post(
        '${ApiConstants.baseUrl}/gas-orders/receive/$deliveryCode',
        body: payload,
        headers: {'Authorization': 'Bearer $token'},
      );

      return response;
    } catch (e) {
      print('[GasOrderService] Error receiving delivery: $e');
      rethrow;
    }
  }
}
