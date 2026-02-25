import '../constants/api_constants.dart';
import '../models/delivery_order.dart';
import 'api_client.dart';

class DeliveryOrderService {
  final ApiClient _apiClient = ApiClient();

  /// GET /api/pos/delivery-orders/home/assigned?status=...
  Future<List<DeliveryOrder>> getHomeDeliveries({
    required String token,
    String? status,
  }) async {
    final url = status != null
        ? '${ApiConstants.deliveryOrdersHome}?status=$status'
        : ApiConstants.deliveryOrdersHome;
    return _fetchList(url, token, 'home deliveries');
  }

  /// GET /api/pos/delivery-orders/commercial/assigned?status=...
  Future<List<DeliveryOrder>> getCommercialDeliveries({
    required String token,
    String? status,
  }) async {
    final url = status != null
        ? '${ApiConstants.deliveryOrdersCommercial}?status=$status'
        : ApiConstants.deliveryOrdersCommercial;
    return _fetchList(url, token, 'commercial deliveries');
  }

  /// GET /api/pos/delivery-orders/site/assigned?status=...  (RETAIL)
  Future<List<DeliveryOrder>> getRetailDeliveries({
    required String token,
    String? status,
  }) async {
    final url = status != null
        ? '${ApiConstants.deliveryOrdersSite}?status=$status'
        : ApiConstants.deliveryOrdersSite;
    return _fetchList(url, token, 'retail/site deliveries');
  }

  /// GET /api/pos/delivery-orders/assigned?status=...  (all types combined)
  Future<List<DeliveryOrder>> getAllAssignedDeliveries({
    required String token,
    String? status,
  }) async {
    final url = status != null
        ? '${ApiConstants.deliveryOrdersAssigned}?status=$status'
        : ApiConstants.deliveryOrdersAssigned;
    return _fetchList(url, token, 'all assigned deliveries');
  }

  /// PATCH /api/pos/delivery-orders/{id}/status
  Future<DeliveryOrder> updateStatus({
    required int deliveryOrderId,
    required String status,
    required int assignedDriverId,
    required String token,
    List<Map<String, dynamic>>? cylinders,
  }) async {
    try {
      final body = <String, dynamic>{
        'status': status,
        'assigned_driver_id': assignedDriverId,
        if (cylinders != null && cylinders.isNotEmpty)
          'cylinders': cylinders,
      };
      final response = await _apiClient.patch(
        ApiConstants.deliveryOrderUpdateStatus(deliveryOrderId),
        body: body,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response['success'] == true && response['data'] != null) {
        return DeliveryOrder.fromJson(
            response['data'] as Map<String, dynamic>);
      }

      throw Exception(
          response['message'] ?? 'Failed to update delivery status');
    } catch (e) {
      print('[DeliveryOrderService] Error updating status: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Legacy aliases kept for backward compatibility
  // ---------------------------------------------------------------------------

  Future<List<DeliveryOrder>> getHomeDeliveryOrders({
    required String token,
    String? status,
  }) =>
      getHomeDeliveries(token: token, status: status);

  Future<List<DeliveryOrder>> getCommercialDeliveryOrders({
    required String token,
    String? status,
  }) =>
      getCommercialDeliveries(token: token, status: status);

  /// PATCH /api/pos/delivery-orders/{orderId}/items/{itemId}/actual-weight
  Future<void> updateItemCurrentWeight({
    required int orderId,
    required int itemId,
    required double currentWeight,
    required String token,
  }) async {
    try {
      final response = await _apiClient.patch(
        ApiConstants.deliveryOrderUpdateItemWeight(orderId, itemId),
        body: {'actual_weight': currentWeight},
        headers: {'Authorization': 'Bearer $token'},
      );

      final isSuccess =
          response['success'] == true || response['status'] == 'success';
      if (!isSuccess) {
        throw Exception(response['message'] ?? 'Failed to update weight');
      }
    } catch (e) {
      print('[DeliveryOrderService] Error updating item weight: $e');
      rethrow;
    }
  }

  Future<DeliveryOrder> updateDeliveryStatus({
    required int deliveryOrderId,
    required String status,
    required int assignedDriverId,
    required String token,
    List<Map<String, dynamic>>? cylinders,
  }) =>
      updateStatus(
        deliveryOrderId: deliveryOrderId,
        status: status,
        assignedDriverId: assignedDriverId,
        token: token,
        cylinders: cylinders,
      );

  // ---------------------------------------------------------------------------
  // Swap assignment endpoints
  // ---------------------------------------------------------------------------

  /// GET /api/pos/delivery-orders/{orderId}/swap-assignments
  Future<List<SwapCylinder>> getSwapAssignments({
    required int orderId,
    required String token,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.swapAssignments(orderId),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        return data
            .map((j) => SwapCylinder.fromJson(j as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('[DeliveryOrderService] Error fetching swap assignments: $e');
      rethrow;
    }
  }

  /// POST /api/pos/delivery-orders/{orderId}/swap-assignments/{assignmentId}/return
  Future<SwapCylinder> markSwapReturned({
    required int orderId,
    required int assignmentId,
    required String token,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.swapAssignmentReturn(orderId, assignmentId),
        body: {},
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response['success'] == true && response['data'] != null) {
        return SwapCylinder.fromJson(
            response['data'] as Map<String, dynamic>);
      }
      throw Exception(
          response['message'] ?? 'Failed to mark cylinder as returned');
    } catch (e) {
      print('[DeliveryOrderService] Error marking swap returned: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------

  Future<List<DeliveryOrder>> _fetchList(
      String url, String token, String label) async {
    try {
      final response = await _apiClient.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      final isSuccess = response['success'] == true ||
          response['status'] == 'success';

      if (isSuccess && response['data'] != null) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        return data
            .map((json) =>
                DeliveryOrder.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      print('[DeliveryOrderService] Error fetching $label: $e');
      rethrow;
    }
  }
}
