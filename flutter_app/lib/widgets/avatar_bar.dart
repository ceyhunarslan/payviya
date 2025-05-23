import 'package:flutter/material.dart';
import 'package:payviya_app/screens/notifications/notifications_screen.dart';
import 'package:payviya_app/services/auth_service.dart';
import 'package:payviya_app/widgets/notification_icon_with_badge.dart';

class AvatarBar extends StatelessWidget implements PreferredSizeWidget {
  const AvatarBar({Key? key}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        const NotificationIconWithBadge(),
        const SizedBox(width: 8),
        CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            AuthService.instance.currentUser?.name?.substring(0, 1).toUpperCase() ?? 'U',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
} 