import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  // Singleton pattern
  static final AuthRepository instance = AuthRepository._internal();
  AuthRepository._internal();

  // Local Backend URL
  final String baseUrl = 'http://localhost:3000/api';

  // --- Auth Methods ---

  Future<Map<String, dynamic>> login(String email, String password) async {
    print('FCM: Logging in via API...');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('FCM: Server Response Status: ${response.statusCode}');
      print('FCM: Server Response Body: ${response.body}');
      final result = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = result['token'];
        final userData = result['user'];
        final statusCode = result['status_code'];

        final prefs = await SharedPreferences.getInstance();
        if (token != null) {
          await prefs.setString('auth_token', token.toString());
        }
        if (userData != null && userData['id'] != null) {
          await prefs.setString('user_id', userData['id'].toString());
        }

        return {
          'success': true,
          'token': token,
          'user': userData,
          'status_code': statusCode,
        };
      } else {
        return {
          'success': false,
          'status_code': result['status_code'],
          'error': result['message'] ??
              'Login failed (${result['status_code'] ?? response.statusCode})'
        };
      }
    } catch (e) {
      print('FCM Auth Error: $e');
      return {'success': false, 'error': 'Connection Error: $e'};
    }
  }

  Future<Map<String, dynamic>> register({
    required String nationalId,
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    print('FCM: Registering via API...');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'national_id': nationalId,
          'email': email,
          'password': password,
          'name': name,
          'phone': phone,
        }),
      );

      print('FCM: Server Response Status: ${response.statusCode}');
      print('FCM: Server Response Body: ${response.body}');
      final result = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': {'userId': result['userId']}
        };
      } else {
        return {
          'success': false,
          'status_code': result['status_code'],
          'error': result['message'] ??
              result['status_code'] ??
              'Registration failed'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection Error: $e'};
    }
  }

  Future<Map<String, dynamic>> setPin(String userId, String pin) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/auth/setup-pin'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userId': userId,
          'pin': pin,
        }),
      );

      print('FCM: Server Response Status: ${response.statusCode}');
      print('FCM: Server Response Body: ${response.body}');
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to set PIN'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection Error: $e'};
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('auth_token');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Get current user profile from API
  Future<Map<String, dynamic>> getProfile() async {
    print('FCM: Fetching profile via API...');
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'error': 'Not logged in'};

      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('FCM: Server Response Status: ${response.statusCode}');
      print('FCM: Server Response Body: ${response.body}');
      final result = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': result['data']};
      } else {
        return {
          'success': false,
          'error': result['message'] ?? 'Failed to fetch profile'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection Error: $e'};
    }
  }

  /// Update user profile fields (name, email, phone, password)
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'error': 'Not logged in'};

      final response = await http.patch(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'error': result['message'] ?? 'Update failed'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection Error: $e'};
    }
  }
}
