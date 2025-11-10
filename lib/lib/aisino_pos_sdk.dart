import 'package:flutter/services.dart';

class AisinoPosSdk {
  static const MethodChannel _channel = MethodChannel('aisino_pos_sdk');

  static Future<String?> startNfcTransaction() async {
    return await _channel.invokeMethod('startNfcTransaction');
  }
}
