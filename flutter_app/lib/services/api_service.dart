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
      return 'http://localhost:8001/api/v1';
    } else {
      // For mobile devices, use your server IP (use the actual IP address when testing on physical devices)
      return 'http://10.0.2.2:8001/api/v1'; // Use 10.0.2.2 for Android emulator
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
  }

  // GET request helper
  static Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      
      return _processResponse(response);
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }
  
  // POST request helper
  static Future<dynamic> post(String endpoint, dynamic data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );
      
      return _processResponse(response);
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }
  
  // Process the HTTP response
  static dynamic _processResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        return jsonDecode(response.body);
      case 400:
        throw Exception('Bad request: ${response.body}');
      case 401:
        throw Exception('Unauthorized');
      case 403:
        throw Exception('Forbidden');
      case 404:
        throw Exception('Resource not found');
      case 500:
        throw Exception('Server error');
      default:
        throw Exception('Error occurred: ${response.statusCode}');
    }
  }
  
  // Campaign-specific API calls
  static Future<List<Campaign>> getCampaigns({int skip = 0, int limit = 20}) async {
    final data = await get('/campaigns?skip=$skip&limit=$limit');
    
    // Convert JSON data to Campaign objects
    List<Campaign> campaigns = [];
    for (var item in data) {
      campaigns.add(Campaign.fromJson(item));
    }
    
    return campaigns;
  }
  
  static Future<Campaign> getCampaignById(int id) async {
    final data = await get('/campaigns/$id');
    return Campaign.fromJson(data);
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
    for (var item in data) {
      campaigns.add(Campaign.fromJson(item));
    }
    
    return campaigns;
  }
  
  static Future<List<Campaign>> getRecommendedCampaigns() async {
    final data = await get('/recommendations/campaigns');
    
    List<Campaign> campaigns = [];
    for (var item in data) {
      campaigns.add(Campaign.fromJson(item));
    }
    
    return campaigns;
  }
  
  // Bank-specific API calls
  static Future<List<Bank>> getBanks() async {
    final data = await get('/banks');
    
    List<Bank> banks = [];
    for (var item in data) {
      banks.add(Bank.fromJson(item));
    }
    
    return banks;
  }
  
  // Credit card-specific API calls
  static Future<List<CreditCard>> getCreditCards() async {
    final data = await get('/credit-cards');
    
    List<CreditCard> cards = [];
    for (var item in data) {
      cards.add(CreditCard.fromJson(item));
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