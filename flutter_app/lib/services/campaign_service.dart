import 'dart:convert';
import 'package:payviya_app/models/campaign.dart';
import 'package:payviya_app/services/api_service.dart';

class CampaignService {
  // Get featured campaigns for the dashboard
  static Future<Map<String, dynamic>> getDashboardCampaigns() async {
    // Get recent campaigns
    final recentCampaigns = await ApiService.getCampaigns(limit: 5);
    
    // Get recommended campaigns
    final recommendedCampaigns = await ApiService.getRecommendedCampaigns();
    
    // Get campaigns by category
    final List<String> popularCategories = ['Supermarket', 'Restaurant', 'Electronics'];
    final Map<String, List<Campaign>> campaignsByCategory = {};
    
    for (String category in popularCategories) {
      try {
        final campaigns = await ApiService.getCampaignsByCategory(category);
        campaignsByCategory[category] = campaigns;
      } catch (e) {
        print('Error fetching campaigns for category $category: $e');
        campaignsByCategory[category] = [];
      }
    }
    
    return {
      'recent': recentCampaigns,
      'recommended': recommendedCampaigns,
      'by_category': campaignsByCategory,
    };
  }
  
  // Get campaign statistics
  static Future<Map<String, dynamic>> getCampaignStats() async {
    final response = await ApiService.get('/api/v1/campaigns/stats');
    return response;
  }
  
  // Get the last captured/used campaign
  static Future<Campaign?> getLastCapturedCampaign() async {
    try {
      final response = await ApiService.get('/api/v1/campaigns/last-captured');
      // If we got here, we have a 200 OK response as ApiService.get() throws exceptions for non-200 responses
      if (response != null) {
        return Campaign.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error fetching last captured campaign: $e');
      return null;
    }
  }
  
  // Get campaigns expiring soon
  static Future<List<Campaign>> getExpiringSoonCampaigns() async {
    final response = await ApiService.get('/api/v1/campaigns/expiring-soon');
    
    List<Campaign> campaigns = [];
    if (response is List) {
      for (var item in response) {
        campaigns.add(Campaign.fromJson(item));
      }
    } else if (response is Map && response.containsKey('items')) {
      for (var item in response['items']) {
        campaigns.add(Campaign.fromJson(item));
      }
    }
    
    return campaigns;
  }
  
  // Get campaign categories
  static Future<List<String>> getCampaignCategories() async {
    final response = await ApiService.get('/api/v1/campaigns/categories');
    if (response is List) {
      return List<String>.from(response);
    } else if (response is Map && response.containsKey('categories')) {
      return List<String>.from(response['categories']);
    }
    return [];
  }
} 