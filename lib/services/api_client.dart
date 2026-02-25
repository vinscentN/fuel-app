import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'session_expiry_service.dart';

const _kConnectivityMessage =
    'The device lost internet connection and failed to finish the process.';

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

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {...defaultHeaders, ...?headers},
        body: jsonEncode(body ?? {}),
      );
      _logResponse(response);
      return await _processResponse(response);
    } on SocketException catch (_) {
      throw Exception(_kConnectivityMessage);
    } on TimeoutException catch (_) {
      throw Exception(_kConnectivityMessage);
    } on http.ClientException catch (_) {
      throw Exception(_kConnectivityMessage);
    }
  }

  Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    print('[API] GET: $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {...defaultHeaders, ...?headers},
      );
      _logResponse(response);
      return await _processResponse(response);
    } on SocketException catch (_) {
      throw Exception(_kConnectivityMessage);
    } on TimeoutException catch (_) {
      throw Exception(_kConnectivityMessage);
    } on http.ClientException catch (_) {
      throw Exception(_kConnectivityMessage);
    }
  }

  Future<Map<String, dynamic>> put(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    print('[API] PUT: $url');
    if (body != null) print('[API] Body: ${jsonEncode(body)}');

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {...defaultHeaders, ...?headers},
        body: jsonEncode(body ?? {}),
      );
      _logResponse(response);
      return await _processResponse(response);
    } on SocketException catch (_) {
      throw Exception(_kConnectivityMessage);
    } on TimeoutException catch (_) {
      throw Exception(_kConnectivityMessage);
    } on http.ClientException catch (_) {
      throw Exception(_kConnectivityMessage);
    }
  }

  Future<Map<String, dynamic>> patch(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    print('[API] PATCH: $url');
    if (body != null) print('[API] Body: ${jsonEncode(body)}');

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {...defaultHeaders, ...?headers},
        body: jsonEncode(body ?? {}),
      );
      _logResponse(response);
      return await _processResponse(response);
    } on SocketException catch (_) {
      throw Exception(_kConnectivityMessage);
    } on TimeoutException catch (_) {
      throw Exception(_kConnectivityMessage);
    } on http.ClientException catch (_) {
      throw Exception(_kConnectivityMessage);
    }
  }

  void _logResponse(http.Response response) {
    print('[API] Response [${response.statusCode}]: ${response.body}');
  }

  Future<Map<String, dynamic>> _processResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = response.body.trim();
      if (body.isEmpty) return {};
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded};
    } else {
      if (response.statusCode == 401) {
        await SessionExpiryService.handleUnauthorized();
        throw Exception('Session expired. Please sign in again.');
      }

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
