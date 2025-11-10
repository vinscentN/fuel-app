import 'package:fuels_app/aisino_pos_sdk.dart';

class PosService {
  Future<Map?> readNfc() => AisinoPosSdk.startNfcTransaction();
  Future<Map?> readChip() => AisinoPosSdk.startChipTransaction();
  Future<Map?> readMagstripe() => AisinoPosSdk.startMagstripeTransaction();
  Future<Map?> requestPin() => AisinoPosSdk.requestPin();
  Future<bool> checkNfcAvailability() => AisinoPosSdk.checkNfcAvailability();
  /// ✅ New: Read device serial number
  Future<String?> readSerialNumber() => AisinoPosSdk.getSerialNumber();
  Future<String?> readImei() => AisinoPosSdk.getImei();
  Future<String?> readPosType() => AisinoPosSdk.getPosType();
}
