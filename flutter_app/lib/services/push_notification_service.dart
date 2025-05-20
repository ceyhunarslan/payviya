import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:payviya_app/models/campaign.dart';
import 'package:payviya_app/services/campaign_service.dart';
import 'package:payviya_app/services/navigation_service.dart';
import 'package:payviya_app/services/notification_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:payviya_app/services/api_service.dart';
import 'package:flutter/services.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🌚 Background message received:');
  print('   Message ID: ${message.messageId}');
  print('   Title: ${message.notification?.title}');
  print('   Body: ${message.notification?.body}');
  print('   Data: ${message.data}');
  
  // Background'da da yönlendirme desteği
  if (message.data['type'] == 'TEST_SCREEN') {
    print('🧪 Background: Navigating to test screen');
    NavigationService.push('/test');
  } else if ((message.data['type'] == 'NEARBY_CAMPAIGN' || message.data['type'] == 'REMINDER_CAMPAIGN') && message.data['campaignId'] != null) {
    print('🎫 Background: Handling campaign notification');
    try {
      final id = int.parse(message.data['campaignId'].toString());
      print('📦 Background: Fetching campaign details for ID: $id');
      
      final campaign = await CampaignService.getCampaignById(id);
      print('✅ Background: Campaign fetched: ${campaign.name}');
      
      NavigationService.pushAndRemoveUntil(
        '/campaign-detail',
        arguments: {'campaign': campaign},
      );
      print('✨ Background: Campaign navigation completed');
    } catch (e) {
      print('❌ Background: Error in campaign navigation: $e');
      print('🔄 Background: Falling back to dashboard');
      NavigationService.navigateToDashboard();
    }
  }
}

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static File? _logFile;
  static const _channel = MethodChannel('com.payviya.app/notifications');
  String? _lastHandledNotificationId;

  static Future<void> _initLogFile() async {
    if (_logFile != null) return;
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      _logFile = File('${directory.path}/app.log');
      
      if (!await _logFile!.exists()) {
        await _logFile!.create();
      }
    } catch (e) {
      print('❌ Error initializing log file: $e');
    }
  }

  static Future<void> _log(String message) async {
    try {
      await _initLogFile();
      if (_logFile != null) {
        final timestamp = DateTime.now().toIso8601String();
        await _logFile!.writeAsString(
          '[$timestamp] $message\n',
          mode: FileMode.append,
        );
      }
    } catch (e) {
      print('❌ Error writing to log file: $e');
    }
  }

  Future<void> initialize() async {
    print('🚀 Initializing push notification service...');
    await _log('🚀 Initializing push notification service...');
    
    try {
      // Set up method channel handler
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'handleNotification') {
          print('📱 Received notification data from iOS: ${call.arguments}');
          await _log('📱 Received notification data from iOS: ${call.arguments}');
          
          if (call.arguments is Map<dynamic, dynamic>) {
            final data = Map<String, dynamic>.from(call.arguments);
            
            // Check for duplicate notification
            final messageId = data['gcm.message_id'];
            if (messageId != null && messageId == _lastHandledNotificationId) {
              print('🔄 Skipping duplicate notification: $messageId');
              await _log('🔄 Skipping duplicate notification: $messageId');
              return false;
            }
            _lastHandledNotificationId = messageId;
            
            print('🎯 Processing notification data: $data');
            await _log('🎯 Processing notification data: $data');
            
            // Add a small delay to ensure navigation context is ready
            await Future.delayed(const Duration(milliseconds: 500));
            
            // Handle the notification data
            await _handleNotificationData(data);
            return true;
          } else {
            print('❌ Invalid notification data format: ${call.arguments}');
            await _log('❌ Invalid notification data format: ${call.arguments}');
            return false;
          }
        }
        return null;
      });

      // Request permissions
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      print('📱 Notification permission status: ${settings.authorizationStatus}');
      await _log('📱 Notification permission status: ${settings.authorizationStatus}');

      // Set up background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Set up notification handlers
      _setupNotificationHandlers();

      // Get FCM token
      String? token = await _fcm.getToken();
      print('=================== FCM TOKEN ===================');
      print('🔑 FCM Token: $token');
      print('===============================================');
      await _log('🔑 FCM Token obtained: ${token?.substring(0, 10)}...');

      print('✅ Push notification service initialized successfully');
      await _log('✅ Push notification service initialized successfully');
    } catch (e) {
      print('❌ Error initializing push notification service: $e');
      await _log('❌ Error initializing push notification service: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        print('👆 Local notification tapped:');
        print('   Payload: ${response.payload}');
        if (response.payload != null) {
          final data = json.decode(response.payload!);
          print('   Decoded data: $data');
          await _handleNotificationData(data);
        }
      },
    );
  }

  void _setupNotificationHandlers() {
    // 1. Foreground handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('📬 Foreground message received:');
      print('   Title: ${message.notification?.title}');
      print('   Body: ${message.notification?.body}');
      print('   Data: ${message.data}');
      await _log('📬 Received foreground message: ${message.notification?.title}');
      await _log('   Data: ${message.data}');
      
      await _showLocalNotification(message);
    });

    // 2. Background opened handler
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      print('🌓 Background notification tapped:');
      print('   Title: ${message.notification?.title}');
      print('   Body: ${message.notification?.body}');
      print('   Data: ${message.data}');
      await _log('🌓 Background notification tapped: ${message.notification?.title}');
      await _log('   Data: ${message.data}');
      
      // Add a small delay to ensure navigation context is ready
      await Future.delayed(const Duration(milliseconds: 500));
      await _handleNotificationData(message.data);
    });

    // 3. Terminated state handler
    _fcm.getInitialMessage().then((RemoteMessage? message) async {
      if (message != null) {
        print('⚫️ App opened from terminated state by notification:');
        print('   Title: ${message.notification?.title}');
        print('   Body: ${message.notification?.body}');
        print('   Data: ${message.data}');
        await _log('⚫️ App opened from terminated state by notification: ${message.notification?.title}');
        await _log('   Data: ${message.data}');
        
        // Add a small delay to ensure navigation context is ready
        await Future.delayed(const Duration(milliseconds: 500));
        await _handleNotificationData(message.data);
      }
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = const AndroidNotificationDetails(
      'default_channel',
      'Default Channel',
      channelDescription: 'Default notification channel',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      subtitle: notification.title,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payload = json.encode(message.data);
    print('📬 Showing local notification with payload: $payload');

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: payload,
    );
  }

  Future<void> _handleNotificationData(Map<String, dynamic> data) async {
    print('🎯 Handling notification data:');
    print('   Raw data: ${json.encode(data)}');
    await _log('🎯 Handling notification data: ${json.encode(data)}');
    
    try {
      // Check if this was a user interaction
      final wasUserInteraction = data['wasUserInteraction'] ?? false;
      if (!wasUserInteraction) {
        print('👆 Skipping navigation - notification was not tapped by user');
        await _log('👆 Skipping navigation - notification was not tapped by user');
        return;
      }
      
      // Check type in both root and data levels
      final type = data['type'] ?? 
                  (data['data'] is Map ? data['data']['type'] : null) ?? 
                  'UNKNOWN';
      
      print('📝 Notification type: $type');
      await _log('📝 Notification type: $type');
      
      // Add a small delay to ensure navigation context is ready
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (type == 'TEST_SCREEN') {
        print('🧪 Attempting to navigate to test screen');
        await _log('🧪 Attempting to navigate to test screen');
        
        NavigationService.pushAndRemoveUntil('/test');
        
        print('✅ Test screen navigation completed');
        await _log('✅ Test screen navigation completed');
        return;
      }
      
      if (type == 'NEARBY_CAMPAIGN' || type == 'REMINDER_CAMPAIGN') {
        final campaignId = data['campaignId'] ?? 
                         (data['data'] is Map ? data['data']['campaignId'] : null);
        final notificationId = data['notificationId'] ??
                         (data['data'] is Map ? data['data']['notificationId'] : null);
                         
        print('📝 Extracted campaignId: $campaignId');
        print('📝 Extracted notificationId: $notificationId');
                         
        if (campaignId != null) {
          print('🎫 Handling campaign notification');
          await _log('🎫 Handling campaign notification');
          try {
            // Mark notification as read if notification ID exists
            if (notificationId != null) {
              final id = int.parse(notificationId.toString());
              print('📝 Marking notification $id as read');
              await _log('📝 Marking notification $id as read');
              await NotificationService.instance.markAsRead(id);
            }

            final id = int.parse(campaignId.toString());
            print('📦 Fetching campaign details for ID: $id');
            await _log('📦 Fetching campaign details for ID: $id');
            
            final campaign = await CampaignService.getCampaignById(id);
            print('✅ Campaign fetched: ${campaign.name}');
            await _log('✅ Campaign fetched: ${campaign.name}');
            
            NavigationService.navigateToCampaignDetail(campaign, clearStack: true);
            
            print('✨ Campaign navigation completed');
            await _log('✨ Campaign navigation completed');
          } catch (e) {
            print('❌ Error in campaign navigation: $e');
            await _log('❌ Error in campaign navigation: $e');
            print('🔄 Falling back to dashboard');
            await _log('🔄 Falling back to dashboard');
            
            NavigationService.navigateToDashboard();
          }
        }
      }
    } catch (e) {
      print('❌ Error handling notification data: $e');
      await _log('❌ Error handling notification data: $e');
      print('🔄 Falling back to test screen');
      await _log('🔄 Falling back to test screen');
      
      NavigationService.pushAndRemoveUntil('/test');
    }
  }

  Future<void> sendTestNotification() async {
    print('🧪 Sending test notification...');
    await _log('🧪 Sending test notification...');
    
    try {
      String? token = await _fcm.getToken();
      if (token == null) {
        print('❌ FCM token is null');
        await _log('❌ FCM token is null');
        return;
      }
      
      final notificationPayload = {
        'title': 'Test Notification',
        'body': 'This is a test notification',
        'fcm_token': token,
        'type': 'TEST_SCREEN',
        'data': {
          'type': 'TEST_SCREEN',
          'businessId': '',
          'campaignId': ''
        }
      };
      
      print('📤 Sending notification request with payload: $notificationPayload');
      await _log('📤 Sending notification request with payload: $notificationPayload');
      
      final response = await ApiService.instance.dio.post(
        '/notifications/send',
        data: notificationPayload,
      );
      
      if (response.data == null) {
        print('❌ Failed to send test notification: No response from server');
        await _log('❌ Failed to send test notification: No response from server');
      } else {
        print('✅ Test notification sent successfully: ${response.data}');
        await _log('✅ Test notification sent successfully: ${response.data}');
      }
    } catch (e) {
      print('❌ Error sending test notification: $e');
      await _log('❌ Error sending test notification: $e');
    }
  }
} 