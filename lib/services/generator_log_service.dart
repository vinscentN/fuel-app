import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'session_expiry_service.dart';

class GeneratorLogService {
  /// Submit a generator usage log
  Future<Map<String, dynamic>> submitGeneratorLog({
    required DateTime startTime,
    required DateTime endTime,
    required String notes,
    required String token,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/generator-logs');

    print('[GeneratorLogService] POST: ${url.toString()}');
    print('[GeneratorLogService] Request body: {start_time: $startTime, end_time: $endTime, notes: $notes}');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          'notes': notes,
        }),
      );

      print('[GeneratorLogService] Response [${response.statusCode}]: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        await SessionExpiryService.handleUnauthorized();
        throw Exception('Session expired. Please sign in again.');
      } else {
        throw Exception('Failed to submit generator log (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      print('[GeneratorLogService] Error: $e');
      rethrow;
    }
  }

  /// Fetch generator logs (optional, for future use)
  Future<List<Map<String, dynamic>>> fetchGeneratorLogs({
    required String token,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var url = '${ApiConstants.baseUrl}/generator-logs';

    // Add query parameters if provided
    final queryParams = <String, String>{};
    if (startDate != null) {
      queryParams['start_date'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['end_date'] = endDate.toIso8601String();
    }

    final uri = Uri.parse(url).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    print('[GeneratorLogService] GET: ${uri.toString()}');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('[GeneratorLogService] Response [${response.statusCode}]: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else if (response.statusCode == 401) {
        await SessionExpiryService.handleUnauthorized();
        throw Exception('Session expired. Please sign in again.');
      } else {
        throw Exception('Failed to fetch generator logs (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      print('[GeneratorLogService] Error: $e');
      rethrow;
    }
  }
}
