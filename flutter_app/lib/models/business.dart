import 'campaign.dart';

class Business {
  final int id;
  final String name;
  final String type;
  final double latitude;
  final double longitude;
  final List<Campaign> activeCampaigns;

  Business({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.activeCampaigns,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing business JSON: $json');
      
      // Convert id to int
      int id = int.parse(json['id'].toString());
      
      // Handle active_campaigns parsing with better error handling
      List<Campaign> campaigns = [];
      if (json['active_campaigns'] != null) {
        var campaignsList = json['active_campaigns'] as List;
        campaigns = campaignsList.map((campaignJson) {
          try {
            if (campaignJson == null) {
              print('Skipping null campaign data');
              return null;
            }

            // Ensure campaignJson is Map<String, dynamic>
            final Map<String, dynamic> fullCampaignJson = 
              campaignJson is Map<String, dynamic> 
                ? Map<String, dynamic>.from(campaignJson)
                : <String, dynamic>{};
            
            // Add default values for required fields
            fullCampaignJson.addAll({
              'category': json['type']?.toString() ?? 'OTHER',
              'campaign_category_name': _getCategoryDisplayName(json['type']?.toString() ?? 'OTHER'),
              'category_id': 0,
              'start_date': DateTime.now().toIso8601String(),
              'end_date': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
              'is_active': true,
              'created_at': DateTime.now().toIso8601String(),
              'priority': 0,
              'requires_enrollment': false,
            });
            
            return Campaign.fromJson(fullCampaignJson);
          } catch (e, stackTrace) {
            print('Error parsing campaign in business: $e');
            print('Stack trace: $stackTrace');
            print('Campaign JSON: $campaignJson');
            return null;
          }
        }).whereType<Campaign>().toList();
      }

      return Business(
        id: id,
        name: json['name'] as String,
        type: json['type'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        activeCampaigns: campaigns,
      );
    } catch (e, stackTrace) {
      print('Error parsing business JSON: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'active_campaigns': activeCampaigns.map((campaign) => campaign.toJson()).toList(),
    };
  }

  static String _getCategoryDisplayName(String category) {
    const Map<String, String> displayNames = {
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
    return displayNames[category] ?? category;
  }
} 