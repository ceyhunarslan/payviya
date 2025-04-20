import 'package:flutter/material.dart';
import 'package:payviya_app/core/theme/app_theme.dart';

class DashboardCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final Color backgroundColor;
  final double elevation;
  final Widget? trailing;
  
  const DashboardCard({
    Key? key,
    required this.child,
    this.title,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 16),
    this.borderRadius = 16,
    this.backgroundColor = Colors.white,
    this.elevation = 1,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: elevation,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                ),
                const Divider(),
              ],
              Padding(
                padding: padding,
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 