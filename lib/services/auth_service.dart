import 'package:logger/logger.dart';

class AuthService {
  final _api = Api();
  final logger = Logger();

  Future<void> updateFCMToken(String fcmToken) async {
    try {
      final deviceInfo = await _getDeviceInfo();
      
      await _api.post(
        '/auth/fcm-token',
        data: {
          'fcm_token': fcmToken,
          'device_id': deviceInfo.deviceId,
          'device_type': deviceInfo.deviceType,
        },
      );
      
      logger.i('FCM token updated successfully');
    } catch (e) {
      logger.e('Error updating FCM token: $e');
      rethrow;
    }
  }

  Future<DeviceInfo> _getDeviceInfo() async {
    // Implementation of _getDeviceInfo method
    // This is a placeholder and should be replaced with the actual implementation
    return DeviceInfo(deviceId: '12345', deviceType: 'Android');
  }
} 