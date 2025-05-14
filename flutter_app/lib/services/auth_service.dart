import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:payviya_app/services/api_service.dart';
import 'package:payviya_app/services/user_service.dart';
import 'package:http/http.dart' as http;
import 'package:payviya_app/models/user.dart';
import 'package:dio/dio.dart';
import 'package:payviya_app/main.dart' show API_BASE_URL;

class AuthService {
  static const storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  
  // Auth-specific API endpoints
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String surname,
    required String phoneNumber,
    required String countryCode,
  }) async {
    try {
      final data = {
        'email': email,
        'password': password,
        'name': name,
        'surname': surname,
        'phone_number': phoneNumber,
        'country_code': countryCode,
        'is_active': true,
      };
      
      print('Sending registration request to: $API_BASE_URL/auth/register');
      print('Request data: $data');
      
      final response = await ApiService.instance.dio.post(
        '/auth/register',
        data: data,
      );
      
      return response.data;
    } catch (e) {
      print('Registration error: $e');
      throw Exception('Registration failed: $e');
    }
  }

  // Login with email and password
  static Future<User> login({required String email, required String password}) async {
    try {
      print('Starting login process for email: $email');
      
      // Use the appropriate content type for form data
      final headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      };
      
      // Prepare the request body
      final body = {
        'username': email,
        'password': password,
      };
      
      // Convert the body to URL encoded format
      final encodedBody = body.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
          
      print('Sending login request to: $API_BASE_URL/auth/login/access-token');
      
      // Send the POST request
      final uri = Uri.parse('$API_BASE_URL/auth/login/access-token');
      final response = await http.post(
        uri, 
        headers: headers, 
        body: encodedBody
      );
      
      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Save the token
        final token = responseData['access_token'];
        if (token == null || token.isEmpty) {
          throw Exception('Token not found in response');
        }
        
        print('Token received, saving to storage...');
        await storage.write(key: _tokenKey, value: token);
        
        // Set the token in the API service
        print('Setting token in API service...');
        ApiService.instance.updateToken(token);
        
        // Fetch the user profile after login and return it
        try {
          print('Fetching user profile...');
          User? user = await UserService.fetchUserProfile();
          if (user == null) {
            throw Exception('Kullanıcı profili alınamadı');
          }
          print('User profile fetched successfully: ${user.name}');
          return user;
        } catch (profileError) {
          print('Error fetching user profile after login: $profileError');
          throw Exception('Giriş başarılı, ancak kullanıcı bilgileri alınamadı');
        }
      } else {
        print('Login failed with status: ${response.statusCode}');
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Giriş başarısız');
      }
    } catch (e) {
      print('Login error: $e');
      // Clear any existing token on login failure
      await storage.delete(key: _tokenKey);
      await ApiService.instance.clearToken();
      throw Exception('Giriş yapılamadı: $e');
    }
  }

  // Send password reset link
  static Future<void> sendPasswordResetLink({required String email}) async {
    try {
      // Email formatını kontrol et
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw Exception('Geçerli bir e-posta adresi girin');
      }

      final response = await ApiService.instance.dio.post<dynamic>(
        '/auth/password-reset/request',
        data: {'email': email},
      );

      print('Password reset response status: ${response.statusCode}');
      print('Password reset response data: ${response.data}');

      if (response.statusCode == 404) {
        throw Exception('Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı');
      }

      if (response.statusCode != 200) {
        throw Exception('Şifre yenileme bağlantısı gönderilemedi. Lütfen tekrar deneyin');
      }

      if (response.data != null && response.data is Map) {
        print('Password reset response: ${response.data['message']}');
      }

    } catch (e) {
      print('Error sending password reset link: $e');
      if (e is DioException) {
        if (e.response?.statusCode == 404) {
          throw Exception('Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı');
        } else if (e.response?.statusCode == 429) {
          throw Exception('Çok fazla deneme yaptınız. Lütfen bir süre bekleyin');
        } else if (e.response?.data != null && e.response?.data['detail'] != null) {
          throw Exception(e.response?.data['detail']);
        }
      }
      throw Exception('Şifre yenileme bağlantısı gönderilemedi. Lütfen tekrar deneyin');
    }
  }

  // Reset password with token
  static Future<void> resetPassword(String token, String newPassword) async {
    try {
      final response = await ApiService.instance.dio.post<Map<String, dynamic>>(
        '/auth/password-reset/confirm',
        data: {
          'token': token,
          'new_password': newPassword,
        },
      );
      
      if (response.statusCode != 200) {
        throw Exception('Şifre güncellenemedi');
      }
    } catch (e) {
      print('Error resetting password: $e');
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          throw Exception('Geçersiz veya süresi dolmuş token');
        } else if (e.response?.data != null && e.response?.data['detail'] != null) {
          throw Exception(e.response?.data['detail']);
        }
      }
      throw Exception('Şifre güncellenemedi: $e');
    }
  }

  // Get token from storage
  static Future<String?> getToken() async {
    try {
      print('Getting token from storage...');
      final token = await storage.read(key: _tokenKey);
      if (token == null || token.isEmpty) {
        print('No token found in storage');
        return null;
      }
      print('Token found in storage');
      return token;
    } catch (e) {
      print('Error reading token from storage: $e');
      return null;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();
      if (token == null) {
        print('No token found, user is not logged in');
        return false;
      }
      
      // Validate token by making a request to /users/me
      print('Making request to validate token...');
      final response = await http.get(
        Uri.parse('$API_BASE_URL/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      
      print('Token validation response status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Initialize auth service
  static Future<void> initializeAuth() async {
    try {
      print('Initializing auth service...');
      final token = await getToken();
      
      if (token != null) {
        print('Found existing token, validating...');
        final isValid = await isLoggedIn();
        
        if (!isValid) {
          print('Token is invalid, attempting refresh');
          final newToken = await refreshToken();
          if (newToken != null) {
            print('Token refreshed successfully');
            ApiService.instance.updateToken(newToken);
          }
        } else {
          print('Token is valid, setting in ApiService');
          ApiService.instance.updateToken(token);
        }
      } else {
        print('No existing token found');
      }
      
      print('Auth service initialization completed');
    } catch (e) {
      print('Error during auth service initialization: $e');
    }
  }

  // Refresh token
  static Future<String?> refreshToken() async {
    try {
      final currentToken = await getToken();
      if (currentToken == null) {
        print('No token to refresh');
        return null;
      }
      
      print('Making refresh token request...');
      final response = await http.post(
        Uri.parse('$API_BASE_URL/auth/login/refresh-token'),
        headers: {
          'Authorization': 'Bearer $currentToken',
          'Accept': 'application/json',
        },
      );
      
      print('Refresh token response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final newToken = responseData['access_token'];
        
        if (newToken != null && newToken.isNotEmpty) {
          print('Saving new token to storage...');
          await storage.write(key: _tokenKey, value: newToken);
          print('Setting new token in API service...');
          ApiService.instance.updateToken(newToken);
          return newToken;
        }
      }
      
      print('Failed to refresh token');
      return null;
    } catch (e) {
      print('Error refreshing token: $e');
      return null;
    }
  }

  // Logout
  static Future<void> logout() async {
    try {
      print('Logging out...');
      await storage.delete(key: _tokenKey);
      await ApiService.instance.clearToken();
      print('Logout completed');
    } catch (e) {
      print('Error during logout: $e');
      rethrow;
    }
  }
} 