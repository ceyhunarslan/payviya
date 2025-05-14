import 'package:flutter/material.dart';
import 'package:payviya_app/core/theme/app_theme.dart';
import 'package:payviya_app/models/campaign.dart';
import 'package:payviya_app/widgets/campaign_template.dart';

class CampaignCard extends StatelessWidget {
  final String bankName;
  final String cardName;
  final String discount;
  final String category;
  final String expiry;
  final Color color;
  final VoidCallback onTap;
  final double? height;
  final double? width;
  final Campaign? campaign;

  const CampaignCard({
    Key? key,
    required this.bankName,
    required this.cardName,
    required this.discount,
    required this.category,
    required this.expiry,
    required this.color,
    required this.onTap,
    this.height = 180,
    this.width = 300,
    this.campaign,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // If a campaign is provided, use CampaignTemplate for consistent UI
    if (campaign != null) {
      return CampaignTemplate(
        campaign: campaign!,
        style: CampaignTemplateStyle.card,
        onTap: onTap,
        width: width,
        height: height,
      );
    }
    
    // Legacy implementation (for backward compatibility)
    final Map<String, Color> bankColors = {
      'Akbank': const Color(0xFFF01C31),       // Red
      'Garanti BBVA': const Color(0xFF00854A), // Green
      'Yapı Kredi': const Color(0xFF010066),   // Dark Blue
      'İş Bankası': const Color(0xFF0A5CA8),   // Blue
      'QNB Finansbank': const Color(0xFF63166E), // Purple
      'TEB': const Color(0xFF133C8B),          // Navy Blue
      'DenizBank': const Color(0xFF008ACF),    // Light Blue
      'Ziraat Bankası': const Color(0xFFE4032E), // Red
      'Halkbank': const Color(0xFF004E9E),     // Blue
      'Vakıfbank': const Color(0xFF00705F),    // Teal
      'HSBC': const Color(0xFFDB0011),         // Red
      'ING': const Color(0xFFFF6200),          // Orange
    };
    
    final bankColor = bankColors[bankName] ?? color;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        margin: const EdgeInsets.only(right: 16, bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              bankColor,
              bankColor.withOpacity(0.85),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: bankColor.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern for visual interest
            Positioned(
              right: -20,
              top: -20,
              child: Opacity(
                opacity: 0.12,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(75),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -50,
              bottom: -50,
              child: Opacity(
                opacity: 0.12,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bank info area with brand color background
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // Bank logo placeholder
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              bankName[0],
                              style: TextStyle(
                                color: bankColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Bank and card info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bankName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                cardName,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (campaign?.categoryName != null)
                                Text(
                                  campaign!.categoryName!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        // Discount badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            discount,
                            style: TextStyle(
                              color: bankColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Bottom info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Category
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      // Expiry
                      Row(
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            color: Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            expiry,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 