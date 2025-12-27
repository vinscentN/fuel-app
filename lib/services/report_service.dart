import 'package:gasman/services/api_client.dart';
import '../constants/api_constants.dart';

class ReportService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> fetchBatchCutoff({
    required String serialNumber,
    required String operatorCode,
  }) async {
    final payload = {
      'serial_number': serialNumber,
      'operator_code': operatorCode,
    };
    final resp = await _api.post(ApiConstants.posBatchCutoff, body: payload);
    return resp;
  }

  // Stubs for future endpoints
  Future<Map<String, dynamic>> fetchLastSale({
    required String serialNumber,
  }) async {
    return _api.get('${ApiConstants.posLastSale}/$serialNumber');
  }

  Future<Map<String, dynamic>> fetchBatchAudit({
    required String serialNumber,
    required String operatorCode,
  }) async {
    final payload = {
      'serial_number': serialNumber,
      'operator_code': operatorCode,
    };
    return _api.post(ApiConstants.posBatchAudit, body: payload);
  }

  Future<Map<String, dynamic>> fetchReversals({
    required String serialNumber,
  }) async {
    return _api.get('${ApiConstants.posReversals}/$serialNumber');
  }
}
