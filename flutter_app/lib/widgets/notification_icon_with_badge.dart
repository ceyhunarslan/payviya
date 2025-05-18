import 'package:flutter/material.dart';
import 'package:payviya_app/services/notification_service.dart';
import 'package:payviya_app/widgets/notification_icon.dart';
import 'package:payviya_app/screens/notifications/notifications_screen.dart';

class NotificationIconWithBadge extends StatefulWidget {
  const NotificationIconWithBadge({super.key});

  @override
  State<NotificationIconWithBadge> createState() => _NotificationIconWithBadgeState();
}

class _NotificationIconWithBadgeState extends State<NotificationIconWithBadge> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final count = await NotificationService.instance.getUnreadCount();
    if (mounted) {
      setState(() {
        _unreadCount = count;
      });
    }
  }

  void _navigateToNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );
    // Refresh count when returning from notifications screen
    _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationIcon(
      notificationCount: _unreadCount,
      onPressed: _navigateToNotifications,
    );
  }
} 