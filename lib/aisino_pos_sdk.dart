import 'package:flutter/services.dart';

class AisinoPosSdk {
  static const MethodChannel _channel = MethodChannel('aisino_pos_sdk');

  static Future<Map?> startNfcTransaction() async {
    final result = await _channel.invokeMethod('startNfcTransaction');
    return Map<String, dynamic>.from(result);
  }

  static Future<Map?> startChipTransaction() async {
    final result = await _channel.invokeMethod('startChipTransaction');
    return Map<String, dynamic>.from(result);
  }

  static Future<Map?> startMagstripeTransaction() async {
    final result = await _channel.invokeMethod('startMagstripeTransaction');
    return Map<String, dynamic>.from(result);
  }

  static Future<Map?> requestPin() async {
    final result = await _channel.invokeMethod('requestPin');
    return Map<String, dynamic>.from(result);
  }

  static Future<bool> checkNfcAvailability() async {
    final result = await _channel.invokeMethod('checkNfcAvailability');
    return result == true;
  }

  static Future<String?> getSerialNumber() async {
    final result = await _channel.invokeMethod<String>("getSerialNumber");
    return result;
  }
  static Future<String?> getImei() async {
    return await _channel.invokeMethod<String>("getImei");
  }

  static Future<String?> getPosType() async {
    return await _channel.invokeMethod<String>("getPosType");
  }

  static Future<void> beep() async {
    await _channel.invokeMethod('beep');
  }

}
