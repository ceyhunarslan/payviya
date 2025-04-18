import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:payviya_app/services/api_service.dart';

class AuthService {
  // Auth-specific API endpoints
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String surname,
  }) async {
    try {
      final data = {
        'email': email,
        'password': password,
        'name': name,
        'surname': surname,
        'is_active': true,
      };
      
      print('Sending registration request to: ${ApiService.baseUrl}/auth/register');
      print('Request data: $data');
      
      // Use the ApiService.post helper method for consistent URL handling
      return await ApiService.post('/auth/register', data);
    } catch (e) {
      print('Registration error: $e');
      throw Exception('Registration failed: $e');
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('Sending login request to: ${ApiService.baseUrl}/auth/login/access-token');
      
      // For OAuth2 form data format, we need a direct HTTP call
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/login/access-token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: 'username=${Uri.encodeComponent(email)}&password=${Uri.encodeComponent(password)}',
      );
      
      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final tokenData = jsonDecode(response.body);
        
        // Save token to local storage
        await _saveToken(tokenData['access_token']);
        
        // Set token in API service for subsequent requests
        ApiService.setToken(tokenData['access_token']);
        
        return tokenData;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Login failed');
      }
    } catch (e) {
      print('Login error: $e');
      throw Exception('Login failed: $e');
    }
  }

  static Future<void> logout() async {
    // Clear token from shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    
    // Clear token from API service
    ApiService.headers.remove('Authorization');
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null && token.isNotEmpty;
  }

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> initializeAuth() async {
    // Check if user is logged in and set token in API service
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      ApiService.setToken(token);
    }
  }
} 