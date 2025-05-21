import 'package:flutter/material.dart';
import 'package:payviya_app/core/theme/app_theme.dart';
import 'package:payviya_app/models/campaign.dart';
import 'package:payviya_app/services/campaign_service.dart';
import 'package:payviya_app/services/user_service.dart';
import 'package:payviya_app/widgets/campaign_card.dart';
import 'package:payviya_app/widgets/campaign_detail_card.dart';
import 'package:payviya_app/widgets/campaign_template.dart';
import 'package:payviya_app/widgets/loading_indicator.dart';
import 'package:payviya_app/widgets/error_indicator.dart';
import 'package:payviya_app/widgets/savings_chart.dart';
import 'package:payviya_app/widgets/dashboard_card.dart';
import 'package:payviya_app/widgets/latest_campaign_card.dart';
import 'package:payviya_app/services/api_service.dart';
import 'package:payviya_app/screens/campaigns/campaign_detail_screen.dart';
import 'package:payviya_app/widgets/user_avatar.dart';
import 'dart:developer' as developer;
import 'package:payviya_app/services/navigation_service.dart';
import 'package:payviya_app/screens/notifications/notifications_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage = '';
  String _userName = '';
  String _userSurname = '';
  late ScrollController _scrollController;
  
  // Campaign data
  List<Campaign> _recentCampaigns = [];
  List<Campaign> _recommendedCampaigns = [];
  Map<String, List<Campaign>> _campaignsByCategory = {};
  Map<String, dynamic> _campaignStats = {
    'total': 0,
    'active': 0,
    'expiring_soon': 0,
  };
  Campaign? _lastCapturedCampaign;
  List<Map<String, dynamic>> _categories = [];
  
  // Total campaign count
  final int _totalCampaignCount = 35;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadDashboardData();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      // Get user profile
      final userData = await UserService.getCurrentUser();
      // Just use the name property since full_name doesn't exist
      _userName = userData?.name ?? 'User';
      _userSurname = userData?.surname ?? '';
      
      // Get campaign data
      try {
        final campaignData = await CampaignService.getDashboardCampaigns();
        _recentCampaigns = campaignData['recent'] as List<Campaign>;
        _recommendedCampaigns = campaignData['recommended'] as List<Campaign>;
        _campaignsByCategory = campaignData['by_category'] as Map<String, List<Campaign>>;
      } catch (e) {
        print('Error loading campaign data: $e');
        // Reset campaign data
        _recentCampaigns = [];
        _recommendedCampaigns = [];
        _campaignsByCategory = {};
      }
      
      // Get campaign stats - each API call in its own try/catch
      try {
        _campaignStats = await CampaignService.getCampaignStats();
      } catch (e) {
        print('Error loading campaign stats: $e');
        _campaignStats = {
          'total': 0,
          'active': 0,
          'expiring_soon': 0,
        };
      }
      
      // Get last captured campaign
      try {
        _lastCapturedCampaign = await CampaignService.getLastCapturedCampaign();
        developer.log("Last captured campaign: ${_lastCapturedCampaign != null ? 'Found' : 'Not found'}");
        if (_lastCapturedCampaign != null) {
          developer.log("Campaign details: Name=${_lastCapturedCampaign!.name}, ID=${_lastCapturedCampaign!.id}");
        }
      } catch (e) {
        developer.log('Error loading last captured campaign: $e');
        _lastCapturedCampaign = null;
      }
      
      // Get campaign categories
      try {
        _categories = await CampaignService.getCampaignCategories();
      } catch (e) {
        print('Error loading campaign categories: $e');
        _categories = [];
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load data: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isLoading 
          ? const Center(child: LoadingIndicator())
          : _hasError 
              ? _buildErrorIndicator()
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Last captured campaign - only show if not null
                        if (_lastCapturedCampaign != null) 
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DashboardCard(
                                  title: 'Son Eklenen Kampanya',
                                  trailing: const Icon(
                                    Icons.new_releases_outlined,
                                    color: AppTheme.primaryColor,
                                  ),
                                  child: CampaignTemplate(
                                    campaign: _lastCapturedCampaign!,
                                    style: CampaignTemplateStyle.discover,
                                    width: double.infinity,
                                    onTap: () {
                                      NavigationService.navigateToCampaignDetail(_lastCapturedCampaign!);
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          )
                        else
                          _buildLastCapturedPlaceholder(),
                        
                        // 3. Recommended campaigns
                        DashboardCard(
                          title: 'En İyi Fırsatlar',
                          subtitle: 'Size özel seçilmiş en avantajlı kampanyalar',
                          trailing: const Icon(
                            Icons.star,
                            color: AppTheme.primaryColor,
                          ),
                          child: _recommendedCampaigns.isNotEmpty
                            ? Column(
                                children: [
                                  // First campaign gets special treatment as the "best offer"
                                  if (_recommendedCampaigns.isNotEmpty) 
                                    GestureDetector(
                                      onTap: () {
                                        NavigationService.navigateToCampaignDetail(_recommendedCampaigns.first);
                                      },
                                      child: CampaignTemplate(
                                        campaign: _recommendedCampaigns.first,
                                        style: CampaignTemplateStyle.discover,
                                        width: double.infinity,
                                        onTap: () {
                                          NavigationService.navigateToCampaignDetail(_recommendedCampaigns.first);
                                        },
                                      ),
                                    ),
                                ],
                              )
                            : _buildNoRecommendationsPlaceholder(),
                        ),
                        
                        // 4. Recent campaigns
                        if (_recentCampaigns.isNotEmpty) ...[
                          DashboardCard(
                            title: 'Yeni Eklenen Kampanyalar',
                            trailing: const Icon(
                              Icons.new_releases_outlined,
                              color: AppTheme.primaryColor,
                            ),
                            child: SizedBox(
                              height: 255,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _recentCampaigns.length,
                                itemBuilder: (context, index) {
                                  final campaign = _recentCampaigns[index];
                                  return CampaignTemplate(
                                    campaign: campaign,
                                    style: CampaignTemplateStyle.discover,
                                    width: 280,
                                    onTap: () {
                                      NavigationService.navigateToCampaignDetail(campaign);
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                        
                        // 5. Campaigns by category
                        if (_campaignsByCategory.isNotEmpty) ...[
                          _buildCategoryCampaigns(),
                        ],
                        
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }
  
  Widget _buildLastCapturedPlaceholder() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
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
              IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppTheme.primaryColor,
                ),
                onPressed: _fetchLastCapturedCampaign,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Henüz yakalanmış kampanya bulunmamaktadır.',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLastCapturedCampaign() {
    if (_lastCapturedCampaign == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
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
              IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppTheme.primaryColor,
                ),
                onPressed: _fetchLastCapturedCampaign,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CampaignTemplate(
            campaign: _lastCapturedCampaign!,
            style: CampaignTemplateStyle.card,
            width: double.infinity,
            onTap: () {
              // Navigate to campaign detail
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
  
  Future<void> _fetchLastCapturedCampaign() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final campaign = await CampaignService.getLastCapturedCampaign();
      developer.log("Fetched campaign: ${campaign != null ? campaign.name : 'null'}");
      setState(() {
        _lastCapturedCampaign = campaign;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Kampanya yüklenirken bir hata oluştu: $e';
        _isLoading = false;
      });
      developer.log('Error fetching last captured campaign: $e');
    }
  }
  
  Widget _buildCategoryCampaigns() {
    // Only show categories with campaigns
    final categoriesToShow = _campaignsByCategory.keys.where(
      (category) => _campaignsByCategory[category]!.isNotEmpty
    ).toList();
    
    if (categoriesToShow.isEmpty) return const SizedBox.shrink();
    
    return Column(
      children: categoriesToShow.map((category) {
        final displayName = CampaignService.getCategoryDisplayName(category);
        
        return DashboardCard(
          title: '$displayName Kampanyaları',
          trailing: Text(
            'Tümünü Gör',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: SizedBox(
            height: 255,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _campaignsByCategory[category]!.length,
              itemBuilder: (context, index) {
                final campaign = _campaignsByCategory[category]![index];
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: CampaignTemplate(
                    campaign: campaign,
                    style: CampaignTemplateStyle.discover,
                    width: 280,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CampaignDetailScreen(campaign: campaign),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [
      const Color(0xFF3A86FF),  // Blue
      const Color(0xFF8338EC),  // Purple
      const Color(0xFFFF006E),  // Pink
      const Color(0xFFFB5607),  // Orange
      const Color(0xFFFFBE0B),  // Yellow
      const Color(0xFF06D6A0),  // Teal
    ];
    
    return colors[index % colors.length];
  }

  Widget _buildErrorIndicator() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load campaign data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestOfferCard(Campaign campaign) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                SizedBox(width: 6),
                Text(
                  "En İyi Fırsat",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          CampaignTemplate(
            campaign: campaign,
            style: CampaignTemplateStyle.card,
            width: double.infinity,
            onTap: () {
              // Navigate to campaign detail
            },
          ),
        ],
      ),
    );
  }
  
  // Helper method to get a consistent color based on bank name
  Color _getBankColor(String bankName) {
    if (bankName.isEmpty) return AppTheme.primaryColor;
    
    // Simple hash function for the bank name
    int hash = 0;
    for (int i = 0; i < bankName.length; i++) {
      hash = bankName.codeUnitAt(i) + ((hash << 5) - hash);
    }
    
    // Convert to color
    final red = ((hash & 0xFF0000) >> 16);
    final green = ((hash & 0x00FF00) >> 8);
    final blue = (hash & 0x0000FF);
    
    // Ensure color is not too light (for contrast with white text)
    return Color.fromARGB(
      255,
      red.clamp(50, 220),
      green.clamp(50, 220),
      blue.clamp(50, 220),
    );
  }

  Widget _buildNoRecommendationsPlaceholder() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
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
                      "En İyi Fırsatlar",
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
              IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppTheme.primaryColor,
                ),
                onPressed: _loadDashboardData,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Henüz önerilen kampanya bulunmamaktadır.',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 