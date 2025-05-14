import 'package:flutter/material.dart';
import 'package:payviya_app/core/theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final String surname;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final bool enableTap;

  const UserAvatar({
    Key? key,
    required this.name,
    required this.surname,
    this.radius = 18,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.enableTap = true,
  }) : super(key: key);

  String _getInitials() {
    final nameInitial = name.isNotEmpty ? name.split(' ').map((name) => name[0]).join('') : '';
    final surnameInitial = surname.isNotEmpty ? surname[0] : '';
    return '$nameInitial$surnameInitial'.toUpperCase();
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.of(context).pushNamed('/profile');
  }

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? AppTheme.primaryColor.withOpacity(0.2),
        border: Border.all(
          color: backgroundColor?.withOpacity(0.3) ?? AppTheme.primaryColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          _getInitials(),
          style: TextStyle(
            fontSize: fontSize ?? radius,
            fontWeight: FontWeight.bold,
            color: textColor ?? AppTheme.primaryColor,
          ),
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