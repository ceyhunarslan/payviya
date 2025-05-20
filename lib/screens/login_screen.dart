import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  // ... (existing code)
}

class _LoginScreenState extends State<LoginScreen> {
  // ... (existing code)

  Future<void> _handleLogin() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _authService.login(_emailController.text, _passwordController.text);
      
      // Get FCM token and update it
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await _authService.updateFCMToken(fcmToken);
      }

      // Navigate to home screen
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ... (rest of the existing code)
} 