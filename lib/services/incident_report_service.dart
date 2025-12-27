import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class IncidentReportService {
  /// Submit an incident report
  Future<Map<String, dynamic>> submitIncidentReport({
    required String issueCategory,
    required String issueDescription,
    required String token,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/site-reports');

    print('[IncidentReportService] POST: ${url.toString()}');
    print('[IncidentReportService] Request body: {issue_category: $issueCategory, issue_description: $issueDescription}');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'issue_category': issueCategory,
          'issue_description': issueDescription,
        }),
      );

      print('[IncidentReportService] Response [${response.statusCode}]: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to submit incident report (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      print('[IncidentReportService] Error: $e');
      rethrow;
    }
  }
}
