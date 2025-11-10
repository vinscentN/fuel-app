import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'api_client.dart';

class CardService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> getBalances({
    required String cardPan,
    required String pvv,
  }) async {
    final payload = {
      'card_pan': cardPan,
      'pvv': pvv,
    };

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final headers = <String, String>{
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    return await _api.post(ApiConstants.cardBalance, body: payload, headers: headers);
  }

  Future<Map<String, dynamic>> setPin({
    required String cardPan,
    required String pin,
    required String pinConfirmation,
  }) async {
    final payload = {
      'card_pan': cardPan,
      'pin': pin,
      'pin_confirmation': pinConfirmation,
    };

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final headers = <String, String>{
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    return await _api.post(ApiConstants.setPin, body: payload, headers: headers);
  }
}
