import 'package:flutter/material.dart';
import 'package:payviya_app/core/theme/app_theme.dart';
import 'package:payviya_app/models/campaign.dart';
import 'package:payviya_app/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:payviya_app/utils/logo_helper.dart';

class CampaignDetailScreen extends StatefulWidget {
  final Campaign campaign;
  
  const CampaignDetailScreen({
    Key? key,
    required this.campaign,
  }) : super(key: key);

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
  Campaign? _campaign;
  
  @override
  void initState() {
    super.initState();
    _campaign = widget.campaign;
  }
  
  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
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

  @override
  Widget build(BuildContext context) {
    if (_campaign == null) {
      return const Scaffold(
        body: Center(
          child: Text('Kampanya bulunamadı'),
        ),
      );
    }

    final bankColor = _getBankColor(_campaign!.bank?.name ?? 'Unknown Bank');
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      bankColor,
                      bankColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Card logo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: LogoHelper.getCardLogoWidget(
                            _campaign!.creditCard?.name ?? 'Unknown Card',
                            _campaign!.creditCard?.logoUrl,
                            size: 80,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Bank name and card name
                      Column(
                        children: [
                          Text(
                            _campaign!.bank?.name ?? 'Unknown Bank',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _campaign!.creditCard?.name ?? 'Unknown Card',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Campaign content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campaign Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Campaign title
                      Text(
                        _campaign!.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Campaign details
                      Row(
                        children: [
                          // Discount badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: bankColor,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              _campaign!.formattedDiscount,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Category badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              border: Border.all(
                                color: Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              _campaign!.categoryName ?? _campaign!.category ?? 'Genel',
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Campaign description
                      Text(
                        _campaign!.description,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade800,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Campaign conditions section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Kampanya Koşulları',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Condition rows
                      if (_campaign!.minAmount != null) ...[
                        _buildConditionRow(
                          'Minimum Harcama:',
                          '${_campaign!.minAmount!.toStringAsFixed(0)} TL',
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      if (_campaign!.maxDiscount != null) ...[
                        _buildConditionRow(
                          'Maksimum İndirim:',
                          '${_campaign!.maxDiscount!.toStringAsFixed(0)} TL',
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      _buildConditionRow(
                        'Başlangıç Tarihi:',
                        '${_campaign!.startDate.day}.${_campaign!.startDate.month}.${_campaign!.startDate.year}',
                      ),
                      const SizedBox(height: 12),
                      
                      _buildConditionRow(
                        'Bitiş Tarihi:',
                        '${_campaign!.endDate.day}.${_campaign!.endDate.month}.${_campaign!.endDate.year}',
                      ),
                      const SizedBox(height: 12),
                      
                      _buildConditionRow(
                        'Kayıt Gerekli:',
                        _campaign!.requiresEnrollment ? 'Evet' : 'Hayır',
                        textColor: _campaign!.requiresEnrollment ? Colors.red.shade700 : Colors.green.shade700,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Official Website Button
                if (_campaign!.creditCard?.applicationUrl != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_campaign!.creditCard?.applicationUrl != null) {
                            _launchURL(_campaign!.creditCard!.applicationUrl!);
                          }
                        },
                        icon: const Icon(Icons.language),
                        label: Text(
                          '${_campaign!.creditCard?.name ?? 'Kart'} Resmi Siteye Git',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getBankColor(_campaign!.bank?.name ?? 'Unknown Bank'),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],

                // Action buttons - MVP2'de aktifleştirilecek
                // Row(
                //   children: [
                //     // Enroll button
                //     if (_campaign!.requiresEnrollment)
                //       Expanded(
                //         child: ElevatedButton.icon(
                //           onPressed: () {
                //             if (_campaign!.enrollmentUrl != null) {
                //               launchUrl(Uri.parse(_campaign!.enrollmentUrl!));
                //             }
                //           },
                //           icon: const Icon(Icons.login),
                //           label: const Text('Katıl'),
                //           style: ElevatedButton.styleFrom(
                //             backgroundColor: _getBankColor(_campaign!.bank?.name ?? 'Unknown Bank'),
                //             foregroundColor: Colors.white,
                //             shape: RoundedRectangleBorder(
                //               borderRadius: BorderRadius.circular(8),
                //             ),
                //             padding: const EdgeInsets.symmetric(
                //               vertical: 12,
                //             ),
                //           ),
                //         ),
                //       ),
                    
                //     // Apply for card button
                //     if (_campaign!.requiresEnrollment)
                //       const SizedBox(width: 12),
                //     Expanded(
                //       child: ElevatedButton.icon(
                //         onPressed: () {
                //           // Launch card application URL
                //           launchUrl(Uri.parse('https://www.garantibbva.com.tr/apply/bonus'));
                //         },
                //         icon: const Icon(Icons.credit_card),
                //         label: const Text('Kart Başvurusu'),
                //         style: ElevatedButton.styleFrom(
                //           backgroundColor: Colors.white,
                //           foregroundColor: _getBankColor(_campaign!.bank?.name ?? 'Unknown Bank'),
                //           side: BorderSide(
                //             color: _getBankColor(_campaign!.bank?.name ?? 'Unknown Bank'),
                //           ),
                //           shape: RoundedRectangleBorder(
                //             borderRadius: BorderRadius.circular(8),
                //           ),
                //           padding: const EdgeInsets.symmetric(
                //             vertical: 12,
                //           ),
                //         ),
                //       ),
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildConditionRow(String label, String value, {Color? textColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textColor ?? AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }
} 