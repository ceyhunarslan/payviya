import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:payviya_app/core/theme/app_theme.dart';
import 'package:payviya_app/screens/splash/splash_screen.dart';
import 'package:payviya_app/screens/auth/login_screen.dart';
import 'package:payviya_app/screens/auth/verify_code_screen.dart';
import 'package:payviya_app/screens/auth/reset_password_screen.dart';
import 'package:payviya_app/screens/dashboard/tabs/profile_tab.dart';
import 'package:payviya_app/screens/campaigns/campaign_detail_screen.dart';
import 'package:payviya_app/screens/dashboard/dashboard_screen.dart';
import 'package:payviya_app/services/navigation_service.dart';
import 'package:payviya_app/services/push_notification_service.dart';
import 'package:payviya_app/screens/test_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
  static const String verifyCode = '/verify-code';
  static const String resetPassword = '/reset-password';
}

Future<void> main() async {
  // Ensure Flutter bindings are initialized first
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    print('📱 Initializing Firebase...');
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');
    
    // Initialize Push Notification Service
    print('🔔 Initializing Push Notification Service...');
    final pushNotificationService = PushNotificationService();
    await pushNotificationService.initialize();
    print('✅ Push Notification Service initialized successfully');
    
    runApp(const PayViyaApp());
  } catch (e, stackTrace) {
    print('❌ Critical error during setup: $e');
    print('Stack trace: $stackTrace');
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
            
          case Routes.verifyCode:
            final args = settings.arguments as Map<String, dynamic>?;
            if (args == null || args['email'] == null) {
              print('❌ Invalid verify code arguments, redirecting to login');
              return MaterialPageRoute(
                builder: (context) => const LoginScreen(),
                settings: settings,
              );
            }
            
            return MaterialPageRoute(
              builder: (context) => VerifyCodeScreen(email: args['email']),
              settings: settings,
            );
            
          case Routes.resetPassword:
            final args = settings.arguments as Map<String, dynamic>?;
            if (args == null || args['email'] == null || args['temp_token'] == null) {
              print('❌ Invalid reset password arguments, redirecting to login');
              return MaterialPageRoute(
                builder: (context) => const LoginScreen(),
                settings: settings,
              );
            }
            
            return MaterialPageRoute(
              builder: (context) => ResetPasswordScreen(
                email: args['email'],
                tempToken: args['temp_token'],
              ),
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