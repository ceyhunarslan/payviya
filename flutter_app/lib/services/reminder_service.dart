import 'package:dio/dio.dart';
import 'package:payviya_app/services/api_service.dart';
import 'package:payviya_app/services/user_service.dart';

class ReminderService {
  static final ApiService _apiService = ApiService.instance;

  static Future<bool> hasReminderForCampaign(int campaignId) async {
    try {
      final user = await UserService.getCurrentUser();
      if (user == null) return false;
      
      final response = await _apiService.dio.get('/campaign-reminders/user/${user.id}');
      final reminders = response.data as List;
      return reminders.any((reminder) => reminder['campaign_id'] == campaignId);
    } catch (e) {
      print('Error checking reminder: $e');
      return false;
    }
  }

  static Future<void> createReminder({
    required int campaignId,
    required DateTime remindAt,
  }) async {
    try {
      final user = await UserService.getCurrentUser();
      if (user == null) throw Exception('User not found');

      // Convert to UTC and ensure proper ISO8601 format with milliseconds
      final formattedDate = remindAt.toUtc().toIso8601String();
      print('Creating reminder with date: $formattedDate');

      final response = await _apiService.dio.post('/campaign-reminders/', data: {
        'user_id': user.id.toString(),
        'campaign_id': campaignId,
        'remind_at': formattedDate,
      });
      
      print('Reminder creation response: ${response.data}');
    } catch (e) {
      print('Error creating reminder: $e');
      rethrow;
    }
  }

  static Future<void> removeReminder(int campaignId) async {
    try {
      final user = await UserService.getCurrentUser();
      if (user == null) throw Exception('User not found');

      final response = await _apiService.dio.get('/campaign-reminders/user/${user.id}');
      final reminders = response.data as List;
      final reminder = reminders.firstWhere(
        (r) => r['campaign_id'] == campaignId,
        orElse: () => null,
      );

      if (reminder != null) {
        await _apiService.dio.delete('/campaign-reminders/${reminder['id']}');
      }
    } catch (e) {
      print('Error removing reminder: $e');
      rethrow;
    }
  }
} 