import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'https://eduprompt.up.railway.app/BE';

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      )
          //.timeout(const Duration(seconds: 15))
      ;

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Server error (${response.statusCode})',
        };
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      // Check if there's any error information
      if (json['error'] != null) {
        final error = json['error'] as Map<String, dynamic>?;
        final messages = error?['message'] as List<dynamic>?;

        return {
          'success': false,
          'message': messages?.isNotEmpty == true
              ? messages![0].toString()
              : (error?['code'] ?? 'Login failed'),
        };
      }

      // Success case: handle the data correctly
      final data = json['data'];
      String? token;

      if (data is String) {
        token = data;
      } else if (data is Map<String, dynamic>) {
        token = data['token']?.toString();
      }

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'No token received from server',
        };
      }

      // Save token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      return {
        'success': true,
        'token': token,
        'message': 'Login successful',
      };

    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Quick helper methods
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}