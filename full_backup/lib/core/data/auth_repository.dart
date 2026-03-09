import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  // Singleton pattern
  static final AuthRepository instance = AuthRepository._internal();
  AuthRepository._internal();

  // Base URL provided by user
  final String baseUrl = 'https://abundantly-unsaturated-hayes.ngrok-free.dev/api';

  // --- Auth Methods (MOCKED FOR LOCAL DEVELOPMENT) ---
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    print('FCM: Logging in (MOCK)...');
    // Simulate a short delay for realism
    await Future.delayed(const Duration(milliseconds: 500));
    
    String role = 'resident';
    if (email == 'admin@gmail.com' || email == 'admin@fcm.com' || email == 'legal@gmail.com') {
      role = 'legal';
    } else if (email == 'technician@gmail.com') {
      role = 'technician';
    }

    final mockData = {
      'token': 'mock_token_123',
      'userId': 'mock_user_id_456',
      'name': role == 'legal' ? 'FCM ADMIN' : (role == 'technician' ? 'TECH WICHAI' : 'RESIDENT USER'),
      'role': role,
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', mockData['token']!);
    await prefs.setString('user_id', mockData['userId']!);
    
    return {'success': true, 'data': mockData};
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String houseId,
  }) async {
    return {'success': true, 'data': {'userId': 'mock_user_id'}};
  }

  Future<Map<String, dynamic>> setPin(String userId, String pin) async {
    return {'success': true, 'data': {'status': 'PIN Set'}};
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

  // Get current user profile (MOCKED)
  Future<Map<String, dynamic>> getProfile() async {
    print('FCM: Fetching profile (MOCK)...');
    return {
      'success': true, 
      'data': {
        'id': 'mock_user_id_456',
        'name': 'FCM ADMIN',
        'email': 'admin@fcm.com',
        'role': 'legal',
      }
    };
  }
}
