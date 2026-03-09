import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  // Singleton pattern
  static final AuthRepository instance = AuthRepository._internal();
  AuthRepository._internal();

  // Base URL provided by user
  final String baseUrl = 'https://abundantly-unsaturated-hayes.ngrok-free.dev/api';

  // --- Auth Methods ---

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Save token and userId
        final prefs = await SharedPreferences.getInstance();
        if (data['token'] != null) {
          await prefs.setString('auth_token', data['token']);
        }
        if (data['userId'] != null) {
          await prefs.setString('user_id', data['userId']);
        }
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String houseId,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'phone': phone,
          'houseId': houseId,
          'role': 'resident', // Default role
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> setPin(String userId, String pin) async {
    final url = Uri.parse('$baseUrl/auth/pin');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'userId': userId,
          'pin': pin,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to set PIN'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
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

  // Get current user profile using session token
  Future<Map<String, dynamic>> getProfile() async {
    print('FCM: Fetching profile...');
    final token = await getToken();
    if (token == null) {
      print('FCM Error: No token found in local storage.');
      return {'success': false, 'error': 'No token found'};
    }

    final url = Uri.parse('$baseUrl/auth/me');
    print('FCM: Requesting GET $url');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      print('FCM: Response Status -> ${response.statusCode}');
      print('FCM: Response Body -> ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('FCM Success: Profile loaded for user: ${data['name']}');
        return {'success': true, 'data': data};
      } else if (response.statusCode == 401) {
        print('FCM Warning: Session Expired (401). Clearing token...');
        // Session Expired logic (from v0.2.3_xx instructions)
        await logout();
        return {'success': false, 'error': 'Session Expired', 'expired': true};
      } else {
        print('FCM Error: Failed with message -> ${data['error']}');
        return {'success': false, 'error': data['error'] ?? 'Failed to get profile'};
      }
    } catch (e) {
      print('FCM Exception: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
}
