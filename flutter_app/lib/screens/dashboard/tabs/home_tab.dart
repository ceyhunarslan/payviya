import 'package:flutter/material.dart';
import 'package:payviya_app/core/theme/app_theme.dart';
import 'package:payviya_app/models/campaign.dart';
import 'package:payviya_app/services/campaign_service.dart';
import 'package:payviya_app/services/user_service.dart';
import 'package:payviya_app/widgets/campaign_card.dart';
import 'package:payviya_app/widgets/loading_indicator.dart';
import 'package:payviya_app/widgets/error_indicator.dart';
import 'package:payviya_app/widgets/savings_chart.dart';
import 'package:payviya_app/widgets/dashboard_card.dart';
import 'package:payviya_app/services/api_service.dart';

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
  List<String> _categories = [];
  
  // Total campaign count
  final int _totalCampaignCount = 35;
  
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
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
      } catch (e) {
        print('Error loading last captured campaign: $e');
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: LoadingIndicator())
          : _hasError 
              ? _buildErrorIndicator()
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: _buildDashboardContent(),
                ),
      ),
    );
  }
  
  Widget _buildDashboardContent() {
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          automaticallyImplyLeading: false,
          floating: true,
          pinned: false,
          snap: false,
          backgroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                radius: 18,
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : "U",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Merhaba, $_userName",
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: AppTheme.textPrimaryColor,
              ),
              onPressed: () {
                // Navigate to notifications
              },
            ),
          ],
        ),
        
        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                
                // 1. Last captured campaign - only show if not null
                if (_lastCapturedCampaign != null) 
                  _buildLastCaughtCampaign(),
                
                // 2. Campaign stats
                _buildCampaignStats(),
                
                // 3. Recommended campaigns
                if (_recommendedCampaigns.isNotEmpty) ...[
                  DashboardCard(
                    title: 'Sizin İçin Öneriler',
                    trailing: const Icon(
                      Icons.recommend,
                      color: AppTheme.primaryColor,
                    ),
                    child: SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _recommendedCampaigns.length,
                        itemBuilder: (context, index) {
                          final campaign = _recommendedCampaigns[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              right: index < _recommendedCampaigns.length - 1 ? 12 : 0,
                            ),
                            child: CampaignCard(
                              bankName: campaign.bank?.name ?? 'Bank',
                              cardName: campaign.creditCard?.name ?? 'Card',
                              discount: campaign.formattedDiscount,
                              category: campaign.category,
                              expiry: campaign.timeRemaining,
                              color: _getColorForIndex(index),
                              width: 280,
                              onTap: () {
                                // Navigate to campaign detail
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
                
                // 4. Recent campaigns
                if (_recentCampaigns.isNotEmpty) ...[
                  DashboardCard(
                    title: 'Yeni Eklenen Kampanyalar',
                    trailing: const Icon(
                      Icons.new_releases_outlined,
                      color: AppTheme.primaryColor,
                    ),
                    child: SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _recentCampaigns.length,
                        itemBuilder: (context, index) {
                          final campaign = _recentCampaigns[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              right: index < _recentCampaigns.length - 1 ? 12 : 0,
                            ),
                            child: CampaignCard(
                              bankName: campaign.bank?.name ?? 'Bank',
                              cardName: campaign.creditCard?.name ?? 'Card',
                              discount: campaign.formattedDiscount,
                              category: campaign.category,
                              expiry: campaign.timeRemaining,
                              color: _getColorForIndex(index),
                              width: 280,
                              onTap: () {
                                // Navigate to campaign detail
                              },
                            ),
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
      ],
    );
  }
  
  Widget _buildLastCaughtCampaign() {
    if (_isLoading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_errorMessage != null) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
              ),
            ),
          ),
        ),
      );
    }
    
    if (_lastCapturedCampaign == null) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Henüz yakalanmış kampanya bulunmamaktadır.',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ),
      );
    }
    
    // Get bank and card info from the campaign
    final bankName = _lastCapturedCampaign!.bank?.name ?? 'Banka';
    final cardName = _lastCapturedCampaign!.creditCard?.name ?? 'Kart';
    final category = _lastCapturedCampaign!.category;
    final discount = _lastCapturedCampaign!.formattedDiscount;
    final expiry = 'Son: ${_lastCapturedCampaign!.endDate.day}/${_lastCapturedCampaign!.endDate.month}/${_lastCapturedCampaign!.endDate.year}';
    
    // Generate a color based on the bank name or use a default
    Color cardColor;
    if (_lastCapturedCampaign!.bank != null) {
      // Use a consistent color based on bank name hash
      final nameHash = bankName.hashCode.abs() % 10;
      const colors = [
        Color(0xFF3A86FF), // Blue
        Color(0xFFFF006E), // Pink
        Color(0xFF8338EC), // Purple
        Color(0xFFFB5607), // Orange
        Color(0xFFFFBE0B), // Yellow
        Color(0xFF3A5A40), // Green
        Color(0xFFE63946), // Red
        Color(0xFF457B9D), // Teal
        Color(0xFF9D4EDD), // Lavender
        Color(0xFF2A9D8F), // Seafoam
      ];
      cardColor = colors[nameHash];
    } else {
      cardColor = const Color(0xFF3A86FF); // Default blue
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CampaignCard(
                  bankName: bankName,
                  cardName: cardName,
                  discount: discount,
                  category: category,
                  expiry: expiry,
                  color: cardColor,
                  width: double.infinity,
                  onTap: () {
                    // Navigate to campaign detail
                  },
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Kaynak: ${_lastCapturedCampaign!.source}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _fetchLastCapturedCampaign,
                  child: const Text('Yenile'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _fetchLastCapturedCampaign() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final campaign = await ApiService.getLastCapturedCampaign();
      setState(() {
        _lastCapturedCampaign = campaign;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Kampanya yüklenirken bir hata oluştu: $e';
        _isLoading = false;
      });
      print('Error fetching last captured campaign: $e');
    }
  }
  
  Widget _buildCampaignStats() {
    return DashboardCard(
      title: 'Kampanya İstatistikleri',
      trailing: Icon(
        Icons.bar_chart,
        color: AppTheme.primaryColor,
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Toplam', _campaignStats['total']?.toString() ?? '0', Icons.all_inclusive),
          _buildStatItem('Aktif', _campaignStats['active']?.toString() ?? '0', Icons.check_circle_outline),
          _buildStatItem('Yakında Bitiyor', _campaignStats['expiring_soon']?.toString() ?? '0', Icons.timer),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }
  
  Widget _buildCategoryCampaigns() {
    // Only show categories with campaigns
    final categoriesToShow = _campaignsByCategory.keys.where(
      (category) => _campaignsByCategory[category]!.isNotEmpty
    ).toList();
    
    if (categoriesToShow.isEmpty) return const SizedBox.shrink();
    
    return Column(
      children: categoriesToShow.map((category) {
        return DashboardCard(
          title: '$category Kampanyaları',
          trailing: Text(
            'Tümünü Gör',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor,
            ),
          ),
          onTap: () {
            // Navigate to category campaigns page
          },
          child: SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _campaignsByCategory[category]!.length,
              itemBuilder: (context, index) {
                final campaign = _campaignsByCategory[category]![index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < _campaignsByCategory[category]!.length - 1 ? 12 : 0,
                  ),
                  child: CampaignCard(
                    bankName: campaign.bank?.name ?? 'Bank',
                    cardName: campaign.creditCard?.name ?? 'Card',
                    discount: campaign.formattedDiscount,
                    category: campaign.category,
                    expiry: campaign.timeRemaining,
                    color: _getColorForIndex(index),
                    width: 280,
                    onTap: () {
                      // Navigate to campaign detail
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
} 