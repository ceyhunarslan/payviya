import 'package:flutter/material.dart';
import 'package:payviya_app/core/theme/app_theme.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  
  const LoadingIndicator({
    Key? key,
    this.message,
    this.size = 40.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
              strokeWidth: 3,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
} 