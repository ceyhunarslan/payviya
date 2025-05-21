import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:payviya_app/models/notification.dart';
import 'package:payviya_app/services/notification_service.dart';
import 'package:payviya_app/models/campaign.dart';
import 'package:payviya_app/services/campaign_service.dart';
import 'package:payviya_app/services/navigation_service.dart';
import 'package:payviya_app/widgets/empty_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService.instance;
  final ScrollController _scrollController = ScrollController();
  
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
    _loadNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!_isLoading && _hasMore) {
        _loadMoreNotifications();
      }
    }
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('tr_TR', null);
  }

  Future<void> _loadNotifications() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _notifications.clear();
    });

    try {
      final NotificationsListResponse result = await _notificationService.getNotifications(
        skip: 0,
        limit: _pageSize,
      );
      
      setState(() {
        _notifications = result.notifications;
        _hasMore = result.hasMore;
        _isLoading = false;
        _currentPage = 1;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bildirimler yüklenirken bir hata oluştu')),
      );
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final NotificationsListResponse result = await _notificationService.getNotifications(
        skip: _currentPage * _pageSize,
        limit: _pageSize,
      );
      
      setState(() {
        _notifications.addAll(result.notifications);
        _hasMore = result.hasMore;
        _isLoading = false;
        _currentPage++;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daha fazla bildirim yüklenirken bir hata oluştu')),
      );
    }
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    // Mark notification as read
    if (!notification.isRead) {
      final success = await _notificationService.markAsRead(notification.id);
      if (success) {
        await _loadNotifications();
      }
    }

    // Handle campaign navigation if campaign data exists
    if (notification.campaign != null && notification.campaign!['id'] != null) {
      try {
        final campaignId = notification.campaign!['id'];
        final campaign = await CampaignService.getCampaignById(campaignId);
        NavigationService.navigateToCampaignDetail(campaign);
      } catch (e) {
        print('Error navigating to campaign: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _notifications.isEmpty && !_isLoading
          ? const EmptyState(
              icon: Icons.notifications_none,
              title: 'Henüz bildiriminiz yok',
              message: 'Yeni bildirimleriniz burada görünecek',
            )
          : ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _notifications.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _notifications.length) {
                  return _buildLoadingIndicator();
                }
                
                final notification = _notifications[index];
                return _buildNotificationItem(notification);
              },
            ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: notification.isRead ? null : Colors.blue.shade50,
      child: Stack(
        children: [
          ListTile(
            title: Text(
              notification.title,
              style: TextStyle(
                fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(notification.body),
                const SizedBox(height: 4),
                Text(
                  _formatDate(notification.sentAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            onTap: () => _handleNotificationTap(notification),
          ),
          if (!notification.isRead)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMMM y HH:mm', 'tr').format(date);
  }
} 