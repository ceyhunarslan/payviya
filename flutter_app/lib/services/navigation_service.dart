import 'package:flutter/material.dart';
import 'package:payviya_app/models/campaign.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<void> navigateToCampaignDetail(Campaign campaign) async {
    if (navigatorKey.currentState != null) {
      // Clear the navigation stack up to the first route (usually dashboard)
      // and then push the campaign detail screen
      await navigatorKey.currentState!.pushNamedAndRemoveUntil(
        '/campaign-detail',
        (route) => route.isFirst,
        arguments: {'campaign': campaign},
      );
    }
  }

  static Future<void> navigateToProfile() async {
    if (navigatorKey.currentState != null) {
      await navigatorKey.currentState!.pushNamed('/profile');
    }
  }

  static Future<void> navigateToNotifications() async {
    if (navigatorKey.currentState != null) {
      await navigatorKey.currentState!.pushNamed('/notifications');
    }
  }

  static Future<void> navigateToLogin() async {
    if (navigatorKey.currentState != null) {
      await navigatorKey.currentState!.pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
  }

  static Future<void> navigateToDashboard() async {
    if (navigatorKey.currentState != null) {
      await navigatorKey.currentState!.pushNamedAndRemoveUntil(
        '/dashboard',
        (route) => false,
      );
    }
  }
} 