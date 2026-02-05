import 'package:gasman/aisino_pos_sdk.dart';

class PosService {
  Future<Map?> readNfc() => AisinoPosSdk.startNfcTransaction();
  Future<Map?> readChip() => AisinoPosSdk.startChipTransaction();
  Future<Map?> readMagstripe() => AisinoPosSdk.startMagstripeTransaction();
  Future<Map?> requestPin() => AisinoPosSdk.requestPin();
  Future<bool> checkNfcAvailability() => AisinoPosSdk.checkNfcAvailability();
  /// ✅ New: Read device serial number
  Future<String?> readSerialNumber() async {
    final raw = await AisinoPosSdk.getSerialNumber();
    final serial = raw?.trim();
    if (serial == null || serial.isEmpty) return null;
    final lower = serial.toLowerCase();
    if (lower == 'unknown' || lower == 'null') return null;
    return serial;
  }
  Future<String?> readImei() => AisinoPosSdk.getImei();
  Future<String?> readPosType() => AisinoPosSdk.getPosType();
}
