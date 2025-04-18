import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:payviya_app/core/theme/app_theme.dart';
import 'package:payviya_app/screens/splash/splash_screen.dart';
import 'package:payviya_app/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  // Initialize auth service
  await AuthService.initializeAuth();
  
  runApp(const PayViyaApp());
}

class PayViyaApp extends StatelessWidget {
  const PayViyaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PayViya',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
} 