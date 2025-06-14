import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://us-central1-workatonflutter.cloudfunctions.net';

  static Future<ApiResponse> deleteAccount({
    required String firebaseUid,
    bool postSystemMessages = true,
  }) async {
    final url = Uri.parse('$baseUrl/deleteAccount');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firebaseUid': firebaseUid,
        'postSystemMessages': postSystemMessages,
      }),
    );
    if (response.statusCode == 200) {
      return ApiResponse(success: true);
    } else {
      String? message;
      try {
        final data = jsonDecode(response.body);
        message = data['message'] ?? 'Unknown error';
      } catch (_) {
        message = 'Unknown error';
      }
      return ApiResponse(success: false, message: message);
    }
  }
}

class ApiResponse {
  final bool success;
  final String? message;
  ApiResponse({required this.success, this.message});
} 