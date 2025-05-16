import 'package:flutter/material.dart';
import 'package:payviya_app/screens/auth/login_screen.dart';
import 'package:payviya_app/screens/auth/forgot_password_screen.dart';
import 'package:payviya_app/screens/auth/verify_code_screen.dart';
import 'package:payviya_app/screens/auth/reset_password_screen.dart';
// ... other imports ...

Map<String, Widget Function(BuildContext)> routes = {
  '/login': (context) => const LoginScreen(),
  '/forgot-password': (context) => const ForgotPasswordScreen(),
  '/verify-code': (context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return VerifyCodeScreen(email: args['email']);
  },
  '/reset-password': (context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return ResetPasswordScreen(
      email: args['email'],
      tempToken: args['temp_token'],
    );
  },
  // ... other routes ...
}; 