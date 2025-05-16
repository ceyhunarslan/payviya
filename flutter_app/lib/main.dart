import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:payviya_app/core/theme/app_theme.dart';
import 'package:payviya_app/screens/splash/splash_screen.dart';
import 'package:payviya_app/screens/auth/login_screen.dart';
import 'package:payviya_app/screens/dashboard/tabs/profile_tab.dart';
import 'package:payviya_app/screens/campaigns/campaign_detail_screen.dart';
import 'package:payviya_app/screens/dashboard/dashboard_screen.dart';
import 'package:payviya_app/services/navigation_service.dart';
import 'package:payviya_app/services/push_notification_service.dart';
import 'package:payviya_app/screens/test_screen.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

// Environment configuration
const String API_BASE_URL = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8001/api/v1',
);

// Route names as constants to avoid typos
class Routes {
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String campaignDetail = '/campaign-detail';
  static const String test = '/test';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Get the log file path
    final directory = await getApplicationDocumentsDirectory();
    final logFile = File('${directory.path}/app.log');
    print('📝 Log file path: ${logFile.path}');
    
    // Create the file if it doesn't exist
    if (!await logFile.exists()) {
      await logFile.create();
      print('✅ Log file created successfully');
    }
    
    // Write initial log entry
    await logFile.writeAsString(
      '=== App Started at ${DateTime.now()} ===\n',
      mode: FileMode.append,
    );
    print('✅ Initial log entry written');
    
    // Run the app in a custom error zone
    runZonedGuarded(() async {
      try {
        // Firebase'i başlat
        print('📱 Initializing Firebase...');
        await Firebase.initializeApp();
        print('✅ Firebase initialized successfully');
        
        // Push notification servisini başlat
        print('🔔 Initializing Push Notification Service...');
        final pushNotificationService = PushNotificationService();
        await pushNotificationService.initialize();
        print('✅ Push Notification Service initialized successfully');
        
        runApp(const PayViyaApp());
        
      } catch (e, stack) {
        print('❌ Error during initialization: $e');
        print('Stack trace: $stack');
        await logFile.writeAsString(
          'Error during initialization: $e\nStack trace: $stack\n',
          mode: FileMode.append,
        );
      }
    }, (error, stackTrace) async {
      // Log any unhandled errors
      print('❌ Unhandled error: $error');
      print('Stack trace: $stackTrace');
      await logFile.writeAsString(
        'Unhandled error: $error\nStack trace: $stackTrace\n',
        mode: FileMode.append,
      );
    });
    
  } catch (e, stack) {
    print('❌ Critical error during setup: $e');
    print('Stack trace: $stack');
  }
}

class PayViyaApp extends StatelessWidget {
  const PayViyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PayViya',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: NavigationService.navigatorKey,
      onGenerateRoute: (settings) {
        print('⚡️ Generating route for: ${settings.name}');
        print('   Arguments: ${settings.arguments}');
        
        switch (settings.name) {
          case Routes.test:
            return MaterialPageRoute(
              builder: (context) => const TestScreen(),
              settings: settings,
            );
            
          case Routes.campaignDetail:
            final args = settings.arguments as Map<String, dynamic>?;
            print('📦 Campaign detail arguments: $args');
            
            if (args == null || args['campaign'] == null) {
              print('❌ Invalid campaign detail arguments, redirecting to dashboard');
              return MaterialPageRoute(
                builder: (context) => const DashboardScreen(),
                settings: settings,
              );
            }
            
            return MaterialPageRoute(
              builder: (context) => CampaignDetailScreen(campaign: args['campaign']),
              settings: settings,
            );
            
          case Routes.splash:
            return MaterialPageRoute(
              builder: (context) => const SplashScreen(),
              settings: settings,
            );
            
          case Routes.login:
            return MaterialPageRoute(
              builder: (context) => const LoginScreen(),
              settings: settings,
            );
            
          case Routes.dashboard:
            return MaterialPageRoute(
              builder: (context) => const DashboardScreen(),
              settings: settings,
            );
            
          case Routes.profile:
            return MaterialPageRoute(
              builder: (context) => const ProfileTab(),
              settings: settings,
            );
            
          default:
            print('⚠️ Route not found: ${settings.name}, redirecting to splash');
            return MaterialPageRoute(
              builder: (context) => const SplashScreen(),
              settings: settings,
            );
        }
      },
      initialRoute: Routes.splash,
    );
  }
} 