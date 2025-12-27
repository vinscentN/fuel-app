import 'dart:convert';

/// Utility class for extracting user-friendly error messages
class ErrorUtils {
  /// Extracts a clean error message from various error formats
  ///
  /// This handles:
  /// - JSON error responses with 'message', 'error', or 'detail' fields
  /// - Raw error strings
  /// - Exception objects
  ///
  /// Returns a user-friendly message or a default fallback
  static String extractErrorMessage(dynamic error, {String? fallback}) {
    if (error == null) {
      return fallback ?? 'An unexpected error occurred';
    }

    // If it's already a string, try to parse it
    if (error is String) {
      return _parseErrorString(error, fallback: fallback);
    }

    // If it's an exception, get the message
    if (error is Exception) {
      return _parseErrorString(error.toString(), fallback: fallback);
    }

    // If it's a map (parsed JSON), extract the message
    if (error is Map) {
      return _extractFromMap(error, fallback: fallback);
    }

    // Fallback for any other type
    return fallback ?? 'An unexpected error occurred';
  }

  /// Parse error string that might contain JSON
  static String _parseErrorString(String errorStr, {String? fallback}) {
    // Remove common exception prefixes
    String cleaned = errorStr
        .replaceFirst('Exception: ', '')
        .replaceFirst('Error: ', '')
        .replaceFirst('FormatException: ', '')
        .trim();

    // Try to find JSON in the string
    final jsonStart = cleaned.indexOf('{');
    final jsonEnd = cleaned.lastIndexOf('}');

    if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
      try {
        final jsonStr = cleaned.substring(jsonStart, jsonEnd + 1);
        final Map<String, dynamic> jsonObj = jsonDecode(jsonStr);
        return _extractFromMap(jsonObj, fallback: fallback);
      } catch (e) {
        // JSON parsing failed, continue with cleaned string
      }
    }

    // If the cleaned string is too long or looks like JSON, return fallback
    if (cleaned.length > 200 ||
        cleaned.startsWith('{') ||
        cleaned.startsWith('[') ||
        cleaned.contains('"message"') ||
        cleaned.contains('"error"')) {
      return fallback ?? 'An unexpected error occurred';
    }

    // Return the cleaned string if it looks like a human-readable message
    return cleaned.isNotEmpty ? cleaned : (fallback ?? 'An unexpected error occurred');
  }

  /// Extract message from a Map (parsed JSON)
  static String _extractFromMap(Map<dynamic, dynamic> map, {String? fallback}) {
    // Try common error message keys in order of preference
    final keys = ['message', 'error', 'detail', 'msg', 'description', 'status'];

    for (final key in keys) {
      if (map.containsKey(key)) {
        final value = map[key];
        if (value != null && value.toString().isNotEmpty) {
          // If the value is itself a map, recurse
          if (value is Map) {
            return _extractFromMap(value, fallback: fallback);
          }
          return value.toString();
        }
      }
    }

    // No message found, return fallback
    return fallback ?? 'An unexpected error occurred';
  }

  /// Extracts error message specifically from HTTP response exceptions
  static String extractHttpErrorMessage(dynamic error, {String? fallback}) {
    String message = extractErrorMessage(error, fallback: fallback);

    // Clean up common HTTP error prefixes
    message = message
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .replaceFirst(RegExp(r'^HTTP\s+\d+:\s*', caseSensitive: false), '')
        .trim();

    return message.isNotEmpty ? message : (fallback ?? 'An unexpected error occurred');
  }

  /// Check if an error message is user-friendly (not JSON or too technical)
  static bool isUserFriendly(String message) {
    if (message.isEmpty) return false;
    if (message.startsWith('{') || message.startsWith('[')) return false;
    if (message.contains('Exception:') || message.contains('Error:')) return false;
    if (message.length > 200) return false;
    return true;
  }
}
