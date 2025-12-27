import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final Map<String, String> defaultHeaders = const {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<Map<String, dynamic>> post(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    print('[API] POST: $url');
    if (body != null) print('[API] Body: ${jsonEncode(body)}');

    final response = await http.post(
      Uri.parse(url),
      headers: {...defaultHeaders, ...?headers},
      body: jsonEncode(body ?? {}),
    );

    _logResponse(response);
    return _processResponse(response);
  }

  Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    print('[API] GET: $url');

    final response = await http.get(
      Uri.parse(url),
      headers: {...defaultHeaders, ...?headers},
    );

    _logResponse(response);
    return _processResponse(response);
  }

  Future<Map<String, dynamic>> put(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    print('[API] PUT: $url');
    if (body != null) print('[API] Body: ${jsonEncode(body)}');

    final response = await http.put(
      Uri.parse(url),
      headers: {...defaultHeaders, ...?headers},
      body: jsonEncode(body ?? {}),
    );

    _logResponse(response);
    return _processResponse(response);
  }

  void _logResponse(http.Response response) {
    print('[API] Response [${response.statusCode}]: ${response.body}');
  }

  Map<String, dynamic> _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = response.body.trim();
      if (body.isEmpty) return {};
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded};
    } else {
      // Try to extract error message from response body
      String errorMessage = 'An unexpected error occurred';

      try {
        final body = response.body.trim();
        if (body.isNotEmpty) {
          final decoded = jsonDecode(body);
          if (decoded is Map<String, dynamic>) {
            // Try to extract message from common error fields
            errorMessage = (decoded['message'] ??
                           decoded['error'] ??
                           decoded['detail'] ??
                           decoded['msg'])?.toString() ?? errorMessage;
          } else if (decoded is String) {
            errorMessage = decoded;
          }
        }
      } catch (_) {
        // If JSON parsing fails, check if body is a readable string
        final body = response.body.trim();
        if (body.isNotEmpty && body.length < 200 && !body.startsWith('<')) {
          errorMessage = body;
        }
      }

      // Throw just the error message, not the full response
      throw Exception(errorMessage);
    }
  }
}

