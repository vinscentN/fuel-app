import 'package:flutter/services.dart';

class PosService {
  static const MethodChannel _channel = MethodChannel('aisino_pos_sdk');

  /// Tap card (NFC)
  Future<String?> startNfcTransaction() async {
    return await _channel.invokeMethod('startNfcTransaction');
  }

  /// Insert chip card (IC)
  Future<String?> startChipTransaction() async {
    return await _channel.invokeMethod('startChipTransaction');
  }

  /// Swipe magstripe
  Future<String?> startMagstripeTransaction() async {
    return await _channel.invokeMethod('startMagstripeTransaction');
  }

  /// Request PIN from PED
  Future<String?> requestPin() async {
    return await _channel.invokeMethod('requestPin');
  }
}
