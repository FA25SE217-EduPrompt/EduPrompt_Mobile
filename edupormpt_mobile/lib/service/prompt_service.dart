import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../service/auth_service.dart';

class PromptService {
  static const String baseUrl = 'https://eduprompt.up.railway.app/BE';

  static List<dynamic> _cachedPrompts = [];
  static bool _isFullyLoaded = false;
  static int _savedPage = 0;

  List<dynamic> get cachedPrompts => _cachedPrompts;
  bool get isFullyLoaded => _isFullyLoaded;
  int get currentSavedPage => _savedPage;

  static List<dynamic> _cachedPublicPrompts = [];
  static bool _isPublicFullyLoaded = false;
  static int _savedPublicPage = 0;

  List<dynamic> get cachedPublicPrompts => _cachedPublicPrompts;
  bool get isPublicFullyLoaded => _isPublicFullyLoaded;

  void clearCache() {
    _cachedPrompts = [];
    _isFullyLoaded = false;
    _savedPage = 0;
    _cachedPublicPrompts = [];
    _isPublicFullyLoaded = false;
    _savedPublicPage = 0;
  }


  Future<Map<String, dynamic>> getMyPrompts({int page = 0, int size = 10}) async {
    if (_isFullyLoaded && page == 0) {
      return {
        'success': true,
        'data': {'content': _cachedPrompts},
        'fromCache': true
      };
    }

    try {
      final token = await AuthService.getToken();
      if (token == null) return {'success': false, 'message': 'User is not logged in'};

      final response = await http.get(
        Uri.parse('$baseUrl/api/prompts/my-prompt?page=$page&size=$size'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List newItems = jsonResponse['data']['content'];
        final int totalPages = jsonResponse['data']['totalPages'];

        if (page == 0) {
          _cachedPrompts = List.from(newItems);
        } else {
          _cachedPrompts.addAll(newItems);
        }

        _savedPage = page;
        if (page >= totalPages - 1) _isFullyLoaded = true;

        return {'success': true, 'data': jsonResponse['data'], 'totalPages': totalPages};
      } else {
        return {'success': false, 'message': _parseErrorMessage(jsonResponse)};
      }
    } on TimeoutException {
      return {'success': false, 'message': 'An error has occurred'};
    } on SocketException {
      return {'success': false, 'message': 'An error has occurred'};
    } catch (e) {
      return {'success': false, 'message': 'An error has occurred'};
    }
  }

  Future<Map<String, dynamic>> sharePrompt(String promptId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return {'success': false, 'message': 'User is not logged in'};

      final response = await http.post(
        Uri.parse('$baseUrl/api/prompts-share/$promptId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'shareUrl': jsonResponse['data'],
        };
      } else {
        return {
          'success': false,
          'message': _parseErrorMessage(jsonResponse),
        };
      }
    } on TimeoutException {
      return {'success': false, 'message': 'An error has occurred'};
    } on SocketException {
      return {'success': false, 'message': 'An error has occurred'};
    } catch (e) {
      return {'success': false, 'message': 'An error has occurred'};
    }
  }

  Future<Map<String, dynamic>> getPromptById(String promptId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return {'success': false, 'message': 'User is not logged in'};

      final response = await http.get(
        Uri.parse('$baseUrl/api/prompts/$promptId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonResponse['data'],
        };
      } else {
        return {'success': false, 'message': _parseErrorMessage(jsonResponse)};
      }
    } on TimeoutException {
      return {'success': false, 'message': 'An error has occurred'};
    } on SocketException {
      return {'success': false, 'message': 'An error has occurred'};
    } catch (e) {
      return {'success': false, 'message': 'An error has occurred'};
    }
  }

  Future<Map<String, dynamic>> getPublicPrompts({int page = 0, int size = 10}) async {
    if (_isPublicFullyLoaded && page == 0) {
      return {'success': true, 'data': {'content': _cachedPublicPrompts}, 'fromCache': true};
    }

    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/prompts/get-non-private?page=$page&size=$size'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List newItems = jsonResponse['data']['content'];
        final int totalPages = jsonResponse['data']['totalPages'];

        if (page == 0) {
          _cachedPublicPrompts = List.from(newItems);
        } else {
          _cachedPublicPrompts.addAll(newItems);
        }

        _savedPublicPage = page;
        if (page >= totalPages - 1) _isPublicFullyLoaded = true;

        return {'success': true, 'data': jsonResponse['data'], 'totalPages': totalPages};
      } else {
        return {'success': false, 'message': _parseErrorMessage(jsonResponse)};
      }
    } on TimeoutException {
      return {'success': false, 'message': 'An error has occurred'};
    } on SocketException {
      return {'success': false, 'message': 'An error has occurred'};
    } catch (e) {
      return {'success': false, 'message': 'An error has occurred'};
    }
  }

  String _parseErrorMessage(Map<String, dynamic> json) {
    if (json['error'] != null) {
      final messages = json['error']['message'] as List?;
      if (messages != null && messages.isNotEmpty) {
        return messages[0].toString();
      }
      return json['error']['code'] ?? 'Unknown API error';
    }
    return 'Failed to load prompts';
  }
}