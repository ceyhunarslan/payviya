import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:payviya_app/models/campaign.dart';

class ApiService {
  // Base URL for API calls - using conditional URL for web vs mobile
  static String get baseUrl {
    if (kIsWeb) {
      // For web deployment, use the localhost with the correct port
      return 'http://localhost:8001';
    } else {
      // For mobile devices, use your server IP (use the actual IP address when testing on physical devices)
      return 'http://10.0.2.2:8001'; // Use 10.0.2.2 for Android emulator
    }
  }
  
  // Headers for API calls
  static Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Set auth token if user is logged in
  static void setToken(String token) {
    headers['Authorization'] = 'Bearer $token';
    print('Token set in headers: Bearer $token');
    
    // Decode JWT to show user info
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = parts[1];
        final normalized = base64Url.normalize(payload);
        final decoded = utf8.decode(base64Url.decode(normalized));
        print('Decoded token: $decoded');
      }
    } catch (e) {
      print('Error decoding token: $e');
    }
  }

  // GET request helper
  static Future<dynamic> get(String endpoint) async {
    final url = '$baseUrl$endpoint';
    print('GET request to: $url');
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      print('Response status code: ${response.statusCode}');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Response body length: ${response.body.length} bytes');
      } else {
        print('Error response: ${response.body}');
      }
      
      return _processResponse(response);
    } catch (e) {
      print('Network error during GET request to $url: $e');
      throw Exception('Failed to connect to server: $e');
    }
  }
  
  // POST request helper
  static Future<dynamic> post(String endpoint, dynamic data) async {
    final url = '$baseUrl$endpoint';
    print('POST request to: $url');
    print('Request body: ${jsonEncode(data)}');
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(data),
      );
      
      print('Response status code: ${response.statusCode}');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Response body length: ${response.body.length} bytes');
      } else {
        print('Error response: ${response.body}');
      }
      
      return _processResponse(response);
    } catch (e) {
      print('Network error during POST request to $url: $e');
      throw Exception('Failed to connect to server: $e');
    }
  }
  
  // Process the HTTP response
  static dynamic _processResponse(http.Response response) {
    try {
      switch (response.statusCode) {
        case 200:
        case 201:
          if (response.body.isEmpty) {
            return {};
          }
          return jsonDecode(response.body);
        case 400:
          print('Bad request: ${response.body}');
          throw Exception('Bad request: ${response.body}');
        case 401:
          print('Unauthorized: ${response.body}');
          throw Exception('Unauthorized');
        case 403:
          print('Forbidden: ${response.body}');
          throw Exception('Forbidden');
        case 404:
          print('Resource not found: ${response.body}');
          throw Exception('Resource not found');
        case 422:
          print('Validation error: ${response.body}');
          throw Exception('Validation error: ${response.body}');
        case 500:
          print('Server error: ${response.body}');
          throw Exception('Server error');
        default:
          print('Error occurred (${response.statusCode}): ${response.body}');
          throw Exception('Error occurred: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception during response processing: $e');
      throw e;
    }
  }
  
  // Campaign-specific API calls
  static Future<List<Campaign>> getCampaigns({int skip = 0, int limit = 20}) async {
    try {
      final data = await get('/api/v1/campaigns?skip=$skip&limit=$limit');
      
      // Convert JSON data to Campaign objects
      List<Campaign> campaigns = [];
      if (data is List) {
        for (var item in data) {
          campaigns.add(Campaign.fromJson(item));
        }
      } else if (data is Map && data.containsKey('items')) {
        for (var item in data['items']) {
          campaigns.add(Campaign.fromJson(item));
        }
      } else {
        print('Unexpected response format: $data');
      }
      
      return campaigns;
    } catch (e) {
      print('Error fetching campaigns: $e');
      rethrow; // Rethrow the exception to be handled by the UI
    }
  }
  
  static Future<Campaign> getCampaignById(int id) async {
    final data = await get('/api/v1/campaigns/$id');
    return Campaign.fromJson(data);
  }
  
  static Future<Map<String, dynamic>> getCampaignStats() async {
    try {
      return await get('/api/v1/campaigns/stats');
    } catch (e) {
      print('Error fetching campaign stats: $e');
      rethrow; // Rethrow the exception to be handled by the UI
    }
  }
  
  static Future<List<String>> getCampaignCategories() async {
    try {
      final data = await get('/api/v1/campaigns/categories');
      
      List<String> categories = [];
      if (data is List) {
        for (var item in data) {
          if (item is String) {
            categories.add(item);
          }
        }
      }
      
      return categories;
    } catch (e) {
      print('Error fetching campaign categories: $e');
      rethrow; // Rethrow the exception to be handled by the UI
    }
  }
  
  static Future<Campaign> getLastCapturedCampaign() async {
    try {
      final data = await get('/api/v1/campaigns/last-captured');
      if (data == null) {
        throw Exception('Empty response from server');
      }
      return Campaign.fromJson(data);
    } catch (e) {
      print('Error fetching last captured campaign: $e');
      rethrow; // Rethrow the exception to be handled by the UI
    }
  }
  
  static Future<List<Campaign>> searchCampaigns(String query) async {
    final data = await get('/campaigns/search?q=$query');
    
    List<Campaign> campaigns = [];
    for (var item in data) {
      campaigns.add(Campaign.fromJson(item));
    }
    
    return campaigns;
  }
  
  static Future<List<Campaign>> getCampaignsByCategory(String category) async {
    final data = await get('/campaigns/category/$category');
    
    List<Campaign> campaigns = [];
    if (data is List) {
      for (var item in data) {
        campaigns.add(Campaign.fromJson(item));
      }
    } else if (data is Map && data.containsKey('items')) {
      for (var item in data['items']) {
        campaigns.add(Campaign.fromJson(item));
      }
    }
    
    return campaigns;
  }
  
  static Future<List<Campaign>> getRecommendedCampaigns() async {
    final data = await get('/recommendations/campaigns');
    
    List<Campaign> campaigns = [];
    if (data is List) {
      for (var item in data) {
        campaigns.add(Campaign.fromJson(item));
      }
    } else if (data is Map && data.containsKey('items')) {
      for (var item in data['items']) {
        campaigns.add(Campaign.fromJson(item));
      }
    }
    
    return campaigns;
  }
  
  // Bank-specific API calls
  static Future<List<Bank>> getBanks() async {
    final data = await get('/banks');
    
    List<Bank> banks = [];
    if (data is List) {
      for (var item in data) {
        banks.add(Bank.fromJson(item));
      }
    } else if (data is Map && data.containsKey('items')) {
      for (var item in data['items']) {
        banks.add(Bank.fromJson(item));
      }
    }
    
    return banks;
  }
  
  // Credit card-specific API calls
  static Future<List<CreditCard>> getCreditCards() async {
    final data = await get('/credit-cards');
    
    List<CreditCard> cards = [];
    if (data is List) {
      for (var item in data) {
        cards.add(CreditCard.fromJson(item));
      }
    } else if (data is Map && data.containsKey('items')) {
      for (var item in data['items']) {
        cards.add(CreditCard.fromJson(item));
      }
    }
    
    return cards;
  }
  
  // Recommendation API calls
  static Future<Map<String, dynamic>> getRecommendation({
    required double amount,
    required String category,
    String? merchantName,
  }) async {
    Map<String, dynamic> requestData = {
      'amount': amount,
      'category': category,
    };
    
    if (merchantName != null) {
      requestData['merchant_name'] = merchantName;
    }
    
    return await post('/recommendations', requestData);
  }
} 