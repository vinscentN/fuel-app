import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'api_client.dart';
import '../models/coupon_validation.dart';

class CouponService {
  final ApiClient _api = ApiClient();

  Future<CouponValidationResult> validateCoupon(String code) async {
    final url = '${ApiConstants.validateCoupon}/$code';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final headers = <String, String>{
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final response = await _api.get(url, headers: headers);
    return CouponValidationResult.fromJson(response);
  }
}

