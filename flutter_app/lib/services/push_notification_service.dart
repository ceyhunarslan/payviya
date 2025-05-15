import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:payviya_app/models/campaign.dart';
import 'package:payviya_app/services/campaign_service.dart';
import 'package:payviya_app/services/navigation_service.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // Global navigator key to use for navigation
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void> initialize() async {
    print('🚀 Initializing push notification service...');
    
    // Request permission for iOS devices
    final settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    print('⚙️ Notification permission status: ${settings.authorizationStatus}');

    // Initialize local notifications
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final initializationSettingsIOS = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    print('📱 Initializing local notifications plugin...');
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
    print('✅ Local notifications plugin initialized');

    // Get FCM token
    String? token = await _fcm.getToken();
    print('=================== FCM TOKEN ===================');
    print('🔑 FCM Token: $token');
    print('===============================================');

    // Configure FCM handlers
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    
    // Background message handler'ı ayarla
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground notification presentation options
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: false,  // Sistem bildirimini devre dışı bırak
      badge: true,
      sound: true,
    );

    // Token refresh listener
    _fcm.onTokenRefresh.listen((newToken) {
      print('=================== NEW FCM TOKEN ===================');
      print('🔄 New FCM Token: $newToken');
      print('==================================================');
    });
    
    // Listen for iOS notification taps
    const channel = MethodChannel('app_channel');
    channel.setMethodCallHandler((call) async {
      if (call.method == 'notificationTapped') {
        final String payload = call.arguments['payload'];
        _handleNotificationTap(payload);
      }
    });
    
    print('✅ Push notification service initialized successfully');
  }

  Future<void> onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) async {
    // Handle iOS foreground notification
    if (payload != null) {
      _handleNotificationTap(payload);
    }
  }

  void onDidReceiveNotificationResponse(NotificationResponse response) async {
    // Handle notification tap
    final String? payload = response.payload;
    if (payload != null) {
      _handleNotificationTap(payload);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      // Show local notification
      await _flutterLocalNotificationsPlugin.show(
        message.hashCode,
        message.notification!.title,
        message.notification!.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'default_channel',
            'Default Channel',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: _createPayload(message.data),
      );
    }
  }

  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Handling a background message: ${message.messageId}');
    _handleNotificationTap(_createPayload(message.data));
  }

  String _createPayload(Map<String, dynamic> data) {
    // Create a JSON string from the data, ensuring IDs are numbers
    return json.encode({
      'businessId': int.parse(data['businessId'].toString()),
      'campaignId': int.parse(data['campaignId'].toString())
    });
  }

  Future<void> _handleNotificationTap(String payload) async {
    try {
      print('Handling notification tap with payload: $payload');
      
      // Parse the payload
      final Map<String, dynamic> data = json.decode(payload);
      
      print('Parsed payload data: $data');
      
      // Get campaign details - IDs are already integers from _createPayload
      final int campaignId = data['campaignId'];
      print('Fetching campaign details for ID: $campaignId');
      
      final campaign = await CampaignService.getCampaignById(campaignId);
      print('Campaign details fetched: ${campaign.name}');
      
      // Use NavigationService for navigation
      await NavigationService.navigateToCampaignDetail(campaign);
      print('Navigation completed using NavigationService');
    } catch (e, stackTrace) {
      print('Error handling notification tap: $e');
      print('Stack trace: $stackTrace');
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🌚 Handling background message: ${message.messageId}');
  print('   Title: ${message.notification?.title}');
  print('   Body: ${message.notification?.body}');
  print('   Data: ${message.data}');
} 