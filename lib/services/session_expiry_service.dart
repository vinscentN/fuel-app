import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class SessionExpiryService {
  static final StreamController<String> _controller =
      StreamController<String>.broadcast();
  static bool _isHandling = false;

  static Stream<String> get onSessionExpired => _controller.stream;

  static Future<void> handleUnauthorized() async {
    if (_isHandling) return;
    _isHandling = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user');
      _controller.add('Session expired. Please sign in again.');
    } finally {
      Future.delayed(const Duration(milliseconds: 800), () {
        _isHandling = false;
      });
    }
  }
}
