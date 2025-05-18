import 'package:dio/dio.dart';
import 'package:payviya_app/models/notification.dart';
import 'package:payviya_app/services/api_service.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  
  NotificationService._internal();

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await ApiService.instance.dio.get('/notifications/history');
      
      if (response.data != null) {
        return (response.data as List)
            .map((item) => NotificationModel.fromJson(item))
            .toList();
      }
      
      return [];
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final notifications = await getNotifications();
      return notifications.where((n) => !n.isRead).length;
    } catch (e) {
      print('Error getting unread notification count: $e');
      return 0;
    }
  }

  Future<bool> markAsRead(int notificationId) async {
    try {
      final response = await ApiService.instance.dio.post(
        '/notifications/$notificationId/read',
      );
      
      return response.data['success'] ?? false;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }
} 