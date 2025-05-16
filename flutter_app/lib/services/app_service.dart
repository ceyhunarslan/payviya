import 'package:payviya_app/services/location_service.dart';
import 'package:payviya_app/services/campaign_service.dart';

class AppService {
  static Future<void> initializeServices() async {
    try {
      print('🚀 Initializing app services...');
      
      // Initialize location service
      final locationService = LocationService();
      final hasPermission = await locationService.handlePermission();
      print('📍 Location permission status: $hasPermission');
      
      if (hasPermission) {
        print('🔄 Starting location tracking service...');
        locationService.startLocationTracking((position) {
          print('📌 Location update received: ${position.latitude}, ${position.longitude}');
          CampaignService.checkAndNotifyNearbyCampaigns(position);
        });
        print('✅ Location tracking service started successfully');
      } else {
        print('⚠️ Location permissions not granted');
      }
    } catch (e) {
      print('❌ Error initializing services: $e');
    }
  }
} 