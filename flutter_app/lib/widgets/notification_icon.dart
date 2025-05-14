import 'package:flutter/material.dart';
import 'package:payviya_app/core/theme/app_theme.dart';

class NotificationIcon extends StatelessWidget {
  final VoidCallback? onPressed;
  final int? notificationCount;

  const NotificationIcon({
    super.key,
    this.onPressed,
    this.notificationCount,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppTheme.textPrimaryColor,
          ),
          onPressed: onPressed ?? () {
            // Navigate to notifications
          },
        ),
        if (notificationCount != null && notificationCount! > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(6),
              ),
              constraints: const BoxConstraints(
                minWidth: 14,
                minHeight: 14,
              ),
              child: Text(
                notificationCount! > 99 ? '99+' : notificationCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
} 