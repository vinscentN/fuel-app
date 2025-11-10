import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'api_client.dart';

class ChangeService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> topupChange({
    required String pan,
    required double amount,
    required int currencyId,
  }) async {
    final url = ApiConstants.changeTopup;
    final payload = {
      'pan': pan,
      'amount': amount,
      'currency_id': currencyId,
    };

    // Try include token if available
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final headers = <String, String>{
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    print('[ChangeService] POST $url -> $payload');
    final resp = await _api.post(url, body: payload, headers: headers);
    print('[ChangeService] Response: $resp');
    return resp;
  }
}

