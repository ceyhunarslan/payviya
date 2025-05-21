import 'package:dio/dio.dart';
import 'package:payviya_app/models/notification.dart';
import 'package:payviya_app/services/api_service.dart';

class NotificationsListResponse {
  final List<NotificationModel> notifications;
  final bool hasMore;
  final int totalCount;

  NotificationsListResponse({
    required this.notifications,
    required this.hasMore,
    required this.totalCount,
  });
}

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  
  NotificationService._internal();

  Future<NotificationsListResponse> getNotifications({
    int skip = 0,
    int limit = 10,
  }) async {
    try {
      final response = await ApiService.instance.dio.get(
        '/notifications/history',
        queryParameters: {
          'skip': skip,
          'limit': limit,
        },
      );
      
      if (response.data != null) {
        final Map<String, dynamic> data = response.data;
        final List<dynamic> notificationsData = data['notifications'] as List<dynamic>;
        final bool hasMore = data['has_more'] as bool;
        final int totalCount = data['total_count'] as int;

        final List<NotificationModel> notifications = notificationsData
            .map((item) => NotificationModel.fromJson(item))
            .toList();
        
        return NotificationsListResponse(
          notifications: notifications,
          hasMore: hasMore,
          totalCount: totalCount,
        );
      }
      
      return NotificationsListResponse(
        notifications: [],
        hasMore: false,
        totalCount: 0,
      );
    } catch (e) {
      print('Error fetching notifications: $e');
      return NotificationsListResponse(
        notifications: [],
        hasMore: false,
        totalCount: 0,
      );
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await getNotifications(limit: 100); // Get a larger batch for counting
      return response.notifications.where((n) => !n.isRead).length;
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