import 'package:flutter/material.dart';
import 'package:payviya_app/core/theme/app_theme.dart';
import 'package:payviya_app/screens/dashboard/dashboard_screen.dart';
import 'package:payviya_app/services/navigation_service.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final String surname;
  final double radius;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final bool enableTap;

  const UserAvatar({
    Key? key,
    required this.name,
    required this.surname,
    this.radius = 20,
    this.backgroundColor = AppTheme.primaryColor,
    this.textColor = Colors.white,
    this.fontSize = 16,
    this.enableTap = true,
  }) : super(key: key);

  String get initials {
    String firstInitial = name.isNotEmpty ? name[0].toUpperCase() : '';
    String secondInitial = surname.isNotEmpty ? surname[0].toUpperCase() : '';
    return '$firstInitial$secondInitial';
  }

  void _navigateToProfile(BuildContext context) {
    // Find the nearest Navigator
    final navigator = Navigator.of(context, rootNavigator: true);
    
    // Find the ancestor DashboardScreen state
    final dashboardState = context.findAncestorStateOfType<DashboardScreenState>();
    
    if (dashboardState != null) {
      // If we found the dashboard state, just switch tabs
      dashboardState.onTabTapped(3);
    } else {
      // If we're not in the dashboard, navigate to it
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => DashboardScreen(
            key: DashboardScreen.globalKey,
            initialTabIndex: 3,
          ),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: Text(
        initials,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    if (!enableTap) return avatar;

    return GestureDetector(
      onTap: () => _navigateToProfile(context),
      child: avatar,
    );
  }
} 