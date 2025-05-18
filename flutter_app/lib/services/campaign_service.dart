import 'dart:convert';
import 'package:payviya_app/models/campaign.dart';
import 'package:payviya_app/services/api_service.dart';
import 'package:payviya_app/services/auth_service.dart';
import 'package:payviya_app/services/user_service.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/business.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class CampaignService {
  static final CampaignService instance = CampaignService._internal();
  static bool _isInitialized = false;
  static const int NEARBY_RADIUS_METERS = 100; // Reduced from 100 to 50 meters

  CampaignService._internal();

  factory CampaignService() {
    return instance;
  }

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Ensure ApiService is ready
      await ApiService.instance.dio.get('/health-check').catchError((e) {
        print('API health check failed: $e');
      });
      
      _isInitialized = true;
      print('Campaign service initialized successfully');
    } catch (e) {
      print('Failed to initialize campaign service: $e');
      rethrow;
    }
  }

  // Get base URL from environment variable or use production URL
  static final String baseUrl = 'https://api.payviya.com/api/v1';
  
  // Category mapping for display purposes
  static Map<String, String> categoryDisplayNames = {
    'GROCERY': 'Market',
    'TRAVEL': 'Seyahat',
    'ELECTRONICS': 'Elektronik',
    'FUEL': 'Akaryakıt',
    'RESTAURANT': 'Restoran',
    'ENTERTAINMENT': 'Eğlence',
    'FASHION': 'Moda',
    'HEALTH': 'Sağlık',
    'OTHER': 'Diğer'
  };
  
  // Get user-friendly category name
  static String getCategoryDisplayName(String apiCategory) {
    return categoryDisplayNames[apiCategory] ?? apiCategory;
  }
  
  // Get featured campaigns for the dashboard
  static Future<Map<String, dynamic>> getDashboardCampaigns() async {
    Map<String, dynamic> result = {
      'recent': <Campaign>[],
      'recommended': <Campaign>[],
      'by_category': <String, List<Campaign>>{},
    };
    
    // Get recent campaigns
    try {
      final recentCampaigns = await ApiService.getCampaigns(limit: 5);
      result['recent'] = recentCampaigns;
    } catch (e) {
      print('Error fetching recent campaigns: $e');
    }
    
    // Get recommended campaigns
    try {
      final recommendedCampaigns = await ApiService.getRecommendedCampaigns();
      result['recommended'] = recommendedCampaigns;
    } catch (e) {
      print('Error fetching recommended campaigns: $e');
    }
    
    // Get all categories and their campaigns
    try {
      final categories = await ApiService.getCampaignCategories();
      final Map<String, List<Campaign>> campaignsByCategory = {};
      
      for (var category in categories) {
        try {
          if (category['id'] != null) {
            final campaigns = await ApiService.getCampaignsByCategory(category['id']);
            campaignsByCategory[category['enum'] as String] = campaigns;
          }
        } catch (e) {
          print('Error fetching campaigns for category ${category['enum']}: $e');
          campaignsByCategory[category['enum'] as String] = [];
        }
      }
      
      result['by_category'] = campaignsByCategory;
    } catch (e) {
      print('Error fetching categories: $e');
      result['by_category'] = {};
    }
    
    return result;
  }
  
  // Get campaign statistics
  static Future<Map<String, dynamic>> getCampaignStats() async {
    try {
      final response = await ApiService.instance.dio.get('/campaigns/stats');
      return response.data;
    } catch (e) {
      print('Error fetching campaign stats: $e');
      return {
        'total': 0,
        'active': 0,
        'expiring_soon': 0,
      };
    }
  }
  
  // Get the last captured/used campaign
  static Future<Campaign?> getLastCapturedCampaign() async {
    try {
      final response = await ApiService.instance.dio.get('/campaigns/last-captured');
      if (response.data != null) {
        return Campaign.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Error fetching last captured campaign: $e');
      return null;
    }
  }
  
  // Get campaign categories
  static Future<List<Map<String, dynamic>>> getCampaignCategories() async {
    try {
      final response = await ApiService.instance.dio.get('/campaigns/categories');
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
  
  // Get campaigns by category
  static Future<List<Campaign>> getCampaignsByCategory(int categoryId) async {
    try {
      final response = await ApiService.instance.dio.get('/campaigns/category/$categoryId');
      if (response.data != null && response.data['items'] != null) {
        return (response.data['items'] as List)
            .map((item) => Campaign.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching campaigns for category $categoryId: $e');
      return [];
    }
  }

  Future<List<Campaign>> getActiveCampaigns() async {
    if (!_isInitialized) {
      throw Exception('Campaign service not initialized');
    }

    try {
      final response = await ApiService.instance.dio.get('/campaigns/active');
      if (response.data is List) {
        return (response.data as List).map((campaign) => Campaign.fromJson(campaign)).toList();
      } else if (response.data is Map && response.data['items'] != null) {
        return (response.data['items'] as List)
            .map((campaign) => Campaign.fromJson(campaign))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting active campaigns: $e');
      return [];
    }
  }

  static Future<void> checkAndNotifyNearbyCampaigns(Position position) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      print('\n🔍 Checking nearby campaigns for notifications...');
      print('Location: ${position.latitude}, ${position.longitude}');
      
      // Get current user
      final currentUser = await UserService.getCurrentUser();
      if (currentUser == null) {
        print('⚠️ Current user not found - cannot send notification');
        return;
      }

      // Get FCM token
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
        print('FCM Token obtained: ${fcmToken?.substring(0, 10)}...');
      } catch (e) {
        print('Error getting FCM token: $e');
        return;
      }

      if (fcmToken == null) {
        print('⚠️ FCM token is null - cannot send notification');
        return;
      }

      // Call backend to process nearby campaigns and send notifications
      try {
        final response = await ApiService.instance.dio.post(
          '/businesses/nearby-campaigns-notify',
          data: {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'radius': NEARBY_RADIUS_METERS,
            'fcm_token': fcmToken,
          },
        );

        print('✅ Nearby campaigns processed: ${response.data}');
      } catch (e) {
        print('❌ Error processing nearby campaigns: $e');
      }

    } catch (e) {
      print('❌ Error checking nearby campaigns: $e');
    }
  }

  // Get campaign by ID
  static Future<Campaign> getCampaignById(int campaignId) async {
    try {
      final response = await ApiService.instance.dio.get('/campaigns/$campaignId');
      return Campaign.fromJson(response.data);
    } catch (e) {
      print('Error getting campaign by ID: $e');
      rethrow;
    }
  }
} 