import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:payviya_app/models/campaign.dart';
import 'package:payviya_app/models/user_credit_card.dart';
import 'package:dio/dio.dart';
import 'package:payviya_app/models/credit_card.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:payviya_app/services/auth_service.dart';

// Import API_BASE_URL constant
import 'package:payviya_app/main.dart' show API_BASE_URL;

class ApiService {
  static final ApiService instance = ApiService._internal();
  final Dio _dio = Dio();
  static bool _isInitialized = false;
  
  // Add public getter for dio instance
  Dio get dio => _dio;
  
  ApiService._internal() {
    _initializeDio();
  }

  void _initializeDio() {
    print('Initializing Dio instance');
    _dio.options.baseUrl = API_BASE_URL;
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    _dio.options.validateStatus = (status) {
      return status != null && status < 500;
    };
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    // Add interceptor for token management
    _dio.interceptors.clear();
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          print('Making request to: ${options.path}');
          print('Request headers before: ${options.headers}');
          
          // Get token before each request
          final token = await AuthService.getToken();
          if (token != null) {
            print('Adding token to request headers: Bearer ${token.substring(0, 10)}...');
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            print('No token available for request to ${options.path}');
          }
          
          print('Final request headers: ${options.headers}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('Received response from: ${response.requestOptions.path}');
          print('Response status: ${response.statusCode}');
          print('Response headers: ${response.headers}');
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          print('Request error for: ${error.requestOptions.path}');
          print('Error type: ${error.type}');
          print('Error message: ${error.message}');
          print('Response status: ${error.response?.statusCode}');
          print('Response data: ${error.response?.data}');
          
          if (error.response?.statusCode == 401) {
            try {
              print('Token expired, attempting refresh');
              final newToken = await AuthService.refreshToken();
              if (newToken != null) {
                print('Token refreshed successfully, retrying request');
                // Update token in headers
                error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
                
                // Create new request with updated token
                final opts = Options(
                  method: error.requestOptions.method,
                  headers: error.requestOptions.headers,
                );
                
                // Retry the request with new token
                print('Retrying request with new token');
                final response = await _dio.request(
                  error.requestOptions.path,
                  options: opts,
                  data: error.requestOptions.data,
                  queryParameters: error.requestOptions.queryParameters,
                );
                
                print('Retry request successful');
                return handler.resolve(response);
              } else {
                print('Token refresh failed');
              }
            } catch (e) {
              print('Error during token refresh: $e');
            }
            // If refresh failed, clear token and logout
            print('Clearing auth data after failed refresh');
            await AuthService.logout();
          }
          return handler.next(error);
        },
      ),
    );
    print('Dio initialization completed');
  }

  // Method to update token
  void updateToken(String token) {
    print('Updating token in API service');
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Method to clear token
  Future<void> clearToken() async {
    print('Clearing token from API service');
    _dio.options.headers.remove('Authorization');
  }

  // Add password reset method
  Future<Map<String, dynamic>> resetPassword(String token, String newPassword) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/password-reset/confirm',
        data: {
          'token': token,
          'new_password': newPassword,
        },
      );
      
      if (response.statusCode != 200) {
        throw Exception('Şifre sıfırlama başarısız oldu');
      }
      
      return response.data ?? {'message': 'Şifreniz başarıyla güncellendi'};
    } on DioException catch (e) {
      print('Error resetting password: $e');
      if (e.response != null) {
        throw Exception(e.response?.data['detail'] ?? 'Şifre sıfırlama başarısız oldu');
      }
      throw Exception('Sunucuya bağlanılamadı');
    }
  }

  // Static get method
  static Future<dynamic> get(String path) async {
    final response = await instance.dio.get(path);
    return response.data;
  }

  // Static post method
  static Future<dynamic> post(String path, dynamic data) async {
    final response = await instance.dio.post(path, data: data);
    return response.data;
  }

  // Static campaign methods
  static Future<List<Campaign>> getCampaigns({int skip = 0, int limit = 20}) async {
    try {
      final response = await instance.dio.get<dynamic>(
        '/campaigns',
        queryParameters: {
          'skip': skip,
          'limit': limit,
        },
      );
      
      final List<Campaign> campaigns = [];
      
      if (response.data is List) {
        // Handle direct list response
        for (var item in response.data) {
          try {
            campaigns.add(Campaign.fromJson(item));
          } catch (e) {
            print('Error parsing campaign: $e');
          }
        }
      } else if (response.data is Map) {
        // Handle paginated response with 'items' field
        final items = response.data['items'];
        if (items is List) {
          for (var item in items) {
            try {
              campaigns.add(Campaign.fromJson(item));
            } catch (e) {
              print('Error parsing campaign: $e');
            }
          }
        }
      }
      
      return campaigns;
    } catch (e) {
      print('Error fetching campaigns: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getCampaignCategories() async {
    try {
      final response = await instance.dio.get<dynamic>('/campaigns/categories');
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      } else if (response.data is Map && response.data['categories'] != null) {
        return List<Map<String, dynamic>>.from(response.data['categories']);
      }
      return [];
    } catch (e) {
      print('Error fetching campaign categories: $e');
      return [];
    }
  }

  static Future<List<Campaign>> getCampaignsByCategory(int categoryId) async {
    try {
      final response = await instance.dio.get<dynamic>('/campaigns/category/$categoryId');
      final List<Campaign> campaigns = [];
      
      if (response.data is List) {
        // Handle direct list response
        for (var item in response.data) {
          try {
            campaigns.add(Campaign.fromJson(item));
          } catch (e) {
            print('Error parsing campaign: $e');
          }
        }
      } else if (response.data is Map && response.data['items'] != null) {
        // Handle paginated response with 'items' field
        final items = response.data['items'];
        if (items is List) {
          for (var item in items) {
            try {
              campaigns.add(Campaign.fromJson(item));
            } catch (e) {
              print('Error parsing campaign: $e');
            }
          }
        }
      }
      
      return campaigns;
    } catch (e) {
      print('Error fetching campaigns for category $categoryId: $e');
      return [];
    }
  }

  static Future<List<Campaign>> getRecommendedCampaigns() async {
    try {
      final response = await instance.dio.get<dynamic>('/recommendations/campaigns');
      
      final List<Campaign> campaigns = [];
      
      if (response.data is List) {
        // Handle direct list response
        for (var item in response.data) {
          try {
            campaigns.add(Campaign.fromJson(item));
          } catch (e) {
            print('Error parsing campaign: $e');
          }
        }
      } else if (response.data is Map) {
        // Handle paginated response with 'items' field
        final items = response.data['items'];
        if (items is List) {
          for (var item in items) {
            try {
              campaigns.add(Campaign.fromJson(item));
            } catch (e) {
              print('Error parsing campaign: $e');
            }
          }
        }
      }
      
      return campaigns;
    } catch (e) {
      print('Error fetching recommended campaigns: $e');
      rethrow;
    }
  }

  static Future<List<Campaign>> searchCampaigns(String query) async {
    final response = await instance.dio.get<Map<String, dynamic>>(
      '/campaigns/search',
      queryParameters: {'q': query},
    );
    
    final List<Campaign> campaigns = [];
    if (response.data != null && response.data!['items'] != null) {
      for (var item in response.data!['items']) {
        campaigns.add(Campaign.fromJson(item));
      }
    }
    return campaigns;
  }

  static Future<List<CreditCardListItem>> getUserCards() async {
    final response = await instance.dio.get('/users/me/cards');
    final List<CreditCardListItem> cards = [];
    if (response.data != null) {
      for (var item in response.data) {
        cards.add(CreditCardListItem.fromJson(item));
      }
    }
    return cards;
  }

  // Generic HTTP methods
  static Future<dynamic> put(String path, dynamic data) async {
    final response = await instance.dio.put(path, data: data);
    return response.data;
  }

  static Future<dynamic> delete(String path) async {
    final response = await instance.dio.delete(path);
    return response.data;
  }

  // Add method to delete a user card
  Future<void> deleteUserCard(int cardId) async {
    await _dio.delete('/users/me/cards/$cardId');
  }
} 