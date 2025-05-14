import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:payviya_app/core/theme/app_theme.dart';
import 'package:payviya_app/screens/splash/splash_screen.dart';
import 'package:payviya_app/screens/auth/login_screen.dart';
import 'package:payviya_app/screens/dashboard/tabs/profile_tab.dart';

// Environment configuration
const String API_BASE_URL = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8001/api/v1',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const PayViyaApp());
}

class PayViyaApp extends StatelessWidget {
  const PayViyaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PayViya',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/profile': (context) => const ProfileTab(),
      },
    );
  }
} 