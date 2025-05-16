import 'package:flutter/material.dart';
import 'package:payviya_app/models/campaign.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static NavigatorState? get navigator => navigatorKey.currentState;
  static File? _logFile;

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

  static void push(String routeName, {Object? arguments}) {
    print('🚀 NavigationService.push: $routeName');
    print('   Arguments: $arguments');
    _log('🚀 Push navigation to: $routeName, Arguments: $arguments');
    
    final nav = navigator;
    if (nav == null) {
      print('❌ Navigator is null');
      _log('❌ Push failed: Navigator is null');
      return;
    }
    
    nav.pushNamed(routeName, arguments: arguments);
    _log('✅ Push navigation completed');
  }

  static void pushAndRemoveUntil(String routeName, {Object? arguments}) {
    print('🚀 NavigationService.pushAndRemoveUntil: $routeName');
    print('   Arguments: $arguments');
    _log('🚀 PushAndRemoveUntil navigation to: $routeName, Arguments: $arguments');
    
    final nav = navigator;
    if (nav == null) {
      print('❌ Navigator is null');
      _log('❌ PushAndRemoveUntil failed: Navigator is null');
      return;
    }
    
    nav.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments
    );
    _log('✅ PushAndRemoveUntil navigation completed');
  }

  static Future<T?> navigateTo<T>(String routeName, {Object? arguments}) async {
    print('🚀 Navigating to: $routeName');
    print('   Arguments: $arguments');
    await _log('🚀 Navigating to: $routeName, Arguments: $arguments');
    
    try {
      if (navigator == null) {
        print('❌ Navigator is null - navigation context not available');
        await _log('❌ Navigation failed: Navigator is null');
        return null;
      }
      
      final result = await navigator!.pushNamed(
        routeName,
        arguments: arguments,
      );
      
      print('✅ Navigation successful');
      await _log('✅ Navigation completed successfully');
      return result as T?;
      
    } catch (e) {
      print('❌ Navigation error: $e');
      await _log('❌ Navigation error: $e');
      return null;
    }
  }

  static Future<T?> navigateAndRemoveUntil<T>(String routeName, {Object? arguments}) async {
    print('🚀 Navigating to $routeName and clearing stack');
    await _log('🚀 Navigating to $routeName and clearing stack, Arguments: $arguments');
    
    try {
      if (navigator == null) {
        print('❌ Navigator is null - navigation context not available');
        await _log('❌ Navigation failed: Navigator is null');
        return null;
      }

      final result = await navigator!.pushNamedAndRemoveUntil(
        routeName,
        (route) => false,
        arguments: arguments,
      );
      
      print('✅ Navigation successful');
      await _log('✅ Navigation completed successfully');
      return result as T?;
      
    } catch (e) {
      print('❌ Navigation error: $e');
      await _log('❌ Navigation error: $e');
      return null;
    }
  }

  static void popUntil(String routeName) {
    print('⬅️ Popping until route: $routeName');
    _log('⬅️ Popping until route: $routeName');
    navigator?.popUntil(ModalRoute.withName(routeName));
    _log('✅ PopUntil completed');
  }

  static void pop<T>([T? result]) {
    print('⬅️ Popping current route');
    _log('⬅️ Popping current route');
    navigator?.pop(result);
    _log('✅ Pop completed');
  }

  static void navigateToTest() {
    print('🚀 Attempting to navigate to test screen');
    _log('🚀 Attempting to navigate to test screen');
    try {
      final navigator = navigatorKey.currentState;
      if (navigator != null) {
        navigator.pushNamed('/test');
        print('✅ Navigation to test screen successful');
        _log('✅ Navigation to test screen successful');
      } else {
        print('❌ Navigator is null');
        _log('❌ Navigation to test screen failed: Navigator is null');
      }
    } catch (e) {
      print('❌ Navigation error: $e');
      _log('❌ Navigation to test screen error: $e');
    }
  }

  static Future<void> navigateToCampaignDetail(Campaign campaign, {bool clearStack = false}) async {
    print('🚀 Navigating to campaign detail:');
    print('   Campaign: ${campaign.name}');
    print('   Clear stack: $clearStack');
    await _log('🚀 Navigating to campaign detail: ${campaign.name}, Clear stack: $clearStack');
    
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      print('❌ Navigator is null, cannot navigate');
      await _log('❌ Campaign detail navigation failed: Navigator is null');
      return;
    }

    try {
      if (clearStack) {
        print('🧹 Clearing navigation stack');
        await _log('🧹 Clearing navigation stack');
        navigator.pushNamedAndRemoveUntil(
          '/campaign-detail',
          (route) => false,
          arguments: {'campaign': campaign},
        );
      } else {
        print('➡️ Normal navigation');
        await _log('➡️ Normal navigation');
        navigator.pushNamed(
          '/campaign-detail',
          arguments: {'campaign': campaign},
        );
      }
      print('✅ Navigation completed successfully');
      await _log('✅ Campaign detail navigation completed successfully');
    } catch (e) {
      print('❌ Navigation error: $e');
      await _log('❌ Campaign detail navigation error: $e');
    }
  }

  static Future<void> navigateToProfile() async {
    print('🚀 Navigating to profile');
    await _log('🚀 Navigating to profile');
    try {
      navigatorKey.currentState?.pushNamed('/profile');
      print('✅ Navigation completed successfully');
      await _log('✅ Profile navigation completed successfully');
    } catch (e) {
      print('❌ Navigation error: $e');
      await _log('❌ Profile navigation error: $e');
    }
  }

  static Future<void> navigateToNotifications() async {
    print('🚀 Navigating to notifications');
    await _log('🚀 Navigating to notifications');
    try {
      navigatorKey.currentState?.pushNamed('/notifications');
      print('✅ Navigation completed successfully');
      await _log('✅ Notifications navigation completed successfully');
    } catch (e) {
      print('❌ Navigation error: $e');
      await _log('❌ Notifications navigation error: $e');
    }
  }

  static Future<void> navigateToLogin() async {
    print('🚀 Navigating to login');
    await _log('🚀 Navigating to login');
    try {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
      print('✅ Navigation completed successfully');
      await _log('✅ Login navigation completed successfully');
    } catch (e) {
      print('❌ Navigation error: $e');
      await _log('❌ Login navigation error: $e');
    }
  }

  static Future<void> navigateToDashboard() async {
    print('🚀 Navigating to dashboard');
    await _log('🚀 Navigating to dashboard');
    try {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/dashboard',
        (route) => false,
      );
      print('✅ Navigation completed successfully');
      await _log('✅ Dashboard navigation completed successfully');
    } catch (e) {
      print('❌ Navigation error: $e');
      await _log('❌ Dashboard navigation error: $e');
    }
  }
}