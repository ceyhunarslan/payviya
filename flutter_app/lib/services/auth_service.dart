import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:payviya_app/services/api_service.dart';
import 'package:payviya_app/services/user_service.dart';
import 'package:http/http.dart' as http;
import 'package:payviya_app/models/user.dart';
import 'package:dio/dio.dart';
import 'package:payviya_app/main.dart' show API_BASE_URL;
import 'package:payviya_app/services/storage_service.dart';
import 'package:payviya_app/utils/password_utils.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';

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
      // Hash the password before sending
      final hashedPassword = PasswordUtils.hashPassword(password);
      
      final data = {
        'email': email,
        'password': hashedPassword,
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
      print('Sending login request to: $API_BASE_URL/auth/login/access-token');
      
      // Hash the password before sending
      final hashedPassword = PasswordUtils.hashPassword(password);
      
      // Use the appropriate content type for form data
      final headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      };
      
      // Prepare the request body
      final body = {
        'username': email,
        'password': hashedPassword,
      };
      
      // Convert the body to URL encoded format
      final encodedBody = body.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
          
      // Send the POST request directly without using ApiService.post
      final uri = Uri.parse('$API_BASE_URL/auth/login/access-token');
      final response = await http.post(
        uri, 
        headers: headers, 
        body: encodedBody
      );
      
      // Reset content type for future requests
      ApiService.instance.dio.options.headers['Content-Type'] = 'application/json';
      
      print('Login response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Login response body:\n${response.body}');
        
        // Save the token
        final token = responseData['access_token'];
        await storage.write(key: _tokenKey, value: token);
        
        // Set token in API service for subsequent requests
        ApiService.instance.updateToken(token);
        
        // Fetch and return user profile
        final userProfile = await UserService.fetchUserProfile();
        if (userProfile == null) {
          throw Exception('Failed to fetch user profile after login');
        }
        
        return userProfile;
      } else {
        throw Exception('Login failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Login error: $e');
      throw Exception('Login failed: $e');
    }
  }

  // Update FCM token
  static Future<void> updateFCMToken() async {
    try {
      // Check if user is logged in
      final isUserLoggedIn = await isLoggedIn();
      if (!isUserLoggedIn) {
        print('User is not logged in, skipping FCM token update');
        return;
      }

      // Get FCM token
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
        print('FCM Token obtained: $fcmToken');
      } catch (e) {
        print('Error getting FCM token: $e');
        return;
      }

      // Get device info
      String deviceId = '';
      String deviceType = '';
      try {
        final deviceInfo = await DeviceInfoPlugin().deviceInfo;
        if (deviceInfo is AndroidDeviceInfo) {
          deviceId = deviceInfo.id;
          deviceType = 'android';
        } else if (deviceInfo is IosDeviceInfo) {
          deviceId = deviceInfo.identifierForVendor ?? '';
          deviceType = 'ios';
        }
        print('Device info obtained - ID: $deviceId, Type: $deviceType');
      } catch (e) {
        print('Error getting device info: $e');
        return;
      }

      if (fcmToken != null && deviceId.isNotEmpty && deviceType.isNotEmpty) {
        print('FCM Token update request - Device ID: $deviceId, Type: $deviceType, Token: $fcmToken');
        await ApiService.instance.dio.post(
          '/auth/fcm-token',
          data: {
            'fcm_token': fcmToken,
            'device_id': deviceId,
            'device_type': deviceType,
          },
        );
        print('FCM token updated successfully');
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  // Password Reset Flow
  static Future<void> requestPasswordReset(String email) async {
    try {
      await ApiService.instance.dio.post(
        '/auth/forgot-password/request',
        data: {'email': email},
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> verifyResetCode({
    required String email,
    required String code,
  }) async {
    try {
      final response = await ApiService.instance.dio.post(
        '/auth/forgot-password/verify',
        data: {
          'email': email,
          'code': code,
        },
      );

      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> resetPassword({
    required String email,
    required String newPassword,
    required String tempToken,
  }) async {
    try {
      // Hash the password before sending
      final hashedPassword = PasswordUtils.hashPassword(newPassword);
      
      await ApiService.instance.dio.post(
        '/auth/reset-password',
        data: {
          'email': email,
          'new_password': hashedPassword,
          'temp_token': tempToken,
        },
      );
    } catch (e) {
      throw _handleError(e);
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

  static Exception _handleError(dynamic error) {
    if (error is DioException) {
      final response = error.response;
      if (response != null && response.data is Map) {
        final message = response.data['detail'] ?? 'Bir hata oluştu';
        return Exception(message);
      }
    }
    return Exception('Bir hata oluştu. Lütfen daha sonra tekrar deneyin.');
  }
} 