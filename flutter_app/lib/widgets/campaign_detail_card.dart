import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:payviya_app/core/theme/app_theme.dart';
import 'package:payviya_app/models/campaign.dart';

class CampaignDetailCard extends StatelessWidget {
  final Campaign campaign;
  final VoidCallback? onTap;
  final VoidCallback? onRefresh;

  const CampaignDetailCard({
    Key? key,
    required this.campaign,
    this.onTap,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    developer.log("Building CampaignDetailCard: ${campaign.name}");
    
    // Get campaign details
    final bankName = campaign.bank?.name ?? 'Unknown Bank';
    final cardName = campaign.creditCard?.name ?? 'Unknown Card';
    final merchant = campaign.merchant?.name;
    final category = campaign.categoryName ?? campaign.category;
    final discount = campaign.formattedDiscount;
    final expiry = campaign.timeRemaining;
    final bankColor = _getBankColor(bankName);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.03),
            Colors.white.withOpacity(0.9),
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with "Son Eklenen Kampanya" label
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_offer_rounded,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(width: 6),
                      Text(
                        "Son Eklenen Kampanya",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (onRefresh != null)
                  IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppTheme.primaryColor,
                    ),
                    onPressed: onRefresh,
                  ),
              ],
            ),
          ),

          // Main card content - clickable
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bank and card info section
                  Row(
                    children: [
                      // Bank logo/avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: bankColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: bankColor.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            bankName.isNotEmpty ? bankName[0] : "B",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Bank and card info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bankName,
                              style: const TextStyle(
                                color: AppTheme.textPrimaryColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cardName,
                              style: const TextStyle(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 14,
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
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: bankColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: bankColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          discount,
                          style: TextStyle(
                            color: bankColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Campaign details
                  Text(
                    campaign.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    campaign.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 16),

                  // Campaign metadata
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(
                        Icons.category_rounded,
                        category,
                        AppTheme.primaryColor,
                      ),
                      if (merchant != null) 
                        _buildInfoChip(
                          Icons.storefront_rounded,
                          merchant,
                          Colors.purple,
                        ),
                      _buildInfoChip(
                        Icons.timer_outlined,
                        expiry,
                        Colors.orange,
                      ),
                    ],
                  ),

                  if (campaign.minAmount > 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Min. Harcama: ${campaign.minAmount.toStringAsFixed(0)} TL',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        if (campaign.maxDiscount != null) ...[
                          const SizedBox(width: 12),
                          Text(
                            'Max. İndirim: ${campaign.maxDiscount!.toStringAsFixed(0)} TL',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBankColor(String bankName) {
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
    
    return bankColors[bankName] ?? AppTheme.primaryColor; // Default if bank not found
  }
} 