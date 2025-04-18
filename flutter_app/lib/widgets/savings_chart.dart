import 'package:flutter/material.dart';
import 'package:payviya_app/core/theme/app_theme.dart';

class SavingsChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const SavingsChart({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Find the maximum value for scaling
    final double maxValue = data.isEmpty
        ? 0
        : data.map((item) => item['amount'] as double).reduce((a, b) => a > b ? a : b);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.chartAxisLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart title and legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Aylık Tasarruf',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.chartPrimary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Birikimleriniz',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Chart container
          SizedBox(
            height: 150, // Increased height for better visibility
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((item) {
                final double amount = item['amount'] as double;
                final double percentage = maxValue > 0 ? amount / maxValue : 0;
                
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Value label
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.chartPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '₺${amount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.chartPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        
                        // Bar
                        Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            // Bar background
                            Container(
                              height: 100,
                              width: 16,
                              decoration: BoxDecoration(
                                color: AppTheme.chartAxisLine,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            // Bar value
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOutQuart,
                              height: 100 * percentage,
                              width: 16,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppTheme.chartPrimary,
                                    AppTheme.chartSecondary,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.chartPrimary.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        
                        // Month label
                        Text(
                          item['month'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Bottom axis
          Container(
            height: 1,
            color: AppTheme.chartAxisLine,
            margin: const EdgeInsets.only(top: 12),
          ),
          const SizedBox(height: 8),
          // Description
          const Center(
            child: Text(
              'Son 5 ay boyunca elde ettiğiniz tasarruflar',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 