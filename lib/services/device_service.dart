import '../constants/api_constants.dart';
import 'api_client.dart';

class DeviceService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> launchDevice({required String serialNumber}) async {
    final resp = await _client.post(
      ApiConstants.deviceLaunch,
      body: {
        'serial_number': serialNumber,
      },
    );
    return resp;
  }
}

