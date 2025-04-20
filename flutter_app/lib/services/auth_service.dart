import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:payviya_app/services/api_service.dart';
import 'package:payviya_app/services/user_service.dart';
import 'package:http/http.dart' as http;
import 'package:payviya_app/models/user.dart';

class AuthService {
  static const storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  
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

  // Login with email and password
  static Future<User> login({required String email, required String password}) async {
    try {
      print('Sending login request to: ${ApiService.baseUrl}/api/v1/auth/login/access-token');
      
      // Use the appropriate content type for form data
      ApiService.headers['Content-Type'] = 'application/x-www-form-urlencoded';
      
      // Prepare the request body
      final body = {
        'username': email,
        'password': password,
      };
      
      // Convert the body to URL encoded format
      final encodedBody = body.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
          
      // Send the POST request directly without using ApiService.post
      final uri = Uri.parse('${ApiService.baseUrl}/api/v1/auth/login/access-token');
      final response = await http.post(
        uri, 
        headers: ApiService.headers, 
        body: encodedBody
      );
      
      // Reset content type for future requests
      ApiService.headers['Content-Type'] = 'application/json';
      
      print('Login response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Login response body:\n${response.body}');
        
        // Save the token
        final token = responseData['access_token'];
        await storage.write(key: _tokenKey, value: token);
        
        // Set the token in the API service
        ApiService.setToken(token);
        
        // Fetch the user profile after login and return it
        try {
          User? user = await UserService.fetchUserProfile();
          if (user == null) {
            throw Exception('Kullanıcı profili alınamadı');
          }
          return user;
        } catch (profileError) {
          print('Error fetching user profile after login: $profileError');
          throw Exception('Giriş başarılı, ancak kullanıcı bilgileri alınamadı');
        }
      } else {
        print('Login error: ${response.body}');
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['detail'] != null) {
            if (errorData['detail'].toString().contains('Incorrect')) {
              throw Exception('E-posta veya şifre hatalı');
            } else if (errorData['detail'].toString().contains('not active')) {
              throw Exception('Hesabınız aktif değil');
            }
            throw Exception(errorData['detail']);
          }
        } catch (e) {
          // If we can't parse the error JSON
          if (response.statusCode == 401) {
            throw Exception('E-posta veya şifre hatalı');
          } else if (response.statusCode == 403) {
            throw Exception('Erişim reddedildi');
          } else if (response.statusCode == 404) {
            throw Exception('Sunucu bağlantısı kurulamadı');
          } else if (response.statusCode >= 500) {
            throw Exception('Sunucu hatası. Lütfen daha sonra tekrar deneyin');
          }
        }
        throw Exception('Giriş başarısız: ${response.statusCode}');
      }
    } catch (e) {
      print('Login error: $e');
      // If it's already an Exception, just rethrow it
      if (e is Exception) {
        throw e;
      }
      throw Exception('Giriş başarısız: $e');
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Get stored token
  static Future<String?> getToken() async {
    return await storage.read(key: _tokenKey);
  }

  // Logout user
  static Future<void> logout() async {
    // Clear the token
    await storage.delete(key: _tokenKey);
    
    // Clear user data
    await UserService.clearUserData();
  }

  static Future<void> initializeAuth() async {
    // Check if user is logged in and set token in API service
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      ApiService.setToken(token);
    }
  }
} 