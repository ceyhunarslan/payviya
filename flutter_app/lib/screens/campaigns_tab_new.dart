import 'package:flutter/material.dart';
import 'package:payviya_app/core/theme/app_theme.dart';
import 'package:payviya_app/models/campaign.dart';
import 'package:payviya_app/screens/campaigns/campaign_detail_screen.dart';
import 'package:payviya_app/screens/campaigns/campaign_discovery_screen.dart';
import 'package:payviya_app/services/api_service.dart';
import 'package:payviya_app/widgets/campaign_template.dart';

class CampaignsTab extends StatefulWidget {
  const CampaignsTab({Key? key}) : super(key: key);

  @override
  State<CampaignsTab> createState() => _CampaignsTabState();
}

class _CampaignsTabState extends State<CampaignsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Actual campaign data
  List<Campaign> _allCampaigns = [];
  List<Campaign> _personalizedCampaigns = [];
  
  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Tümü',
      'icon': Icons.all_inclusive,
    },
    {
      'name': 'GROCERY',
      'icon': Icons.shopping_cart,
      'display': 'Süpermarket',
    },
    {
      'name': 'TRAVEL',
      'icon': Icons.flight,
      'display': 'Seyahat',
    },
    {
      'name': 'ELECTRONICS',
      'icon': Icons.devices,
      'display': 'Elektronik',
    },
    {
      'name': 'FUEL',
      'icon': Icons.local_gas_station,
      'display': 'Akaryakıt',
    },
  ];
  
  String _selectedCategory = 'Tümü';
  
  bool _isLoadingAll = true;
  bool _isLoadingPersonalized = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllCampaigns();
    _loadPersonalizedCampaigns();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllCampaigns() async {
    setState(() {
      _isLoadingAll = true;
      _error = null;
    });

    try {
      final campaigns = await ApiService.getCampaigns(limit: 20);
      setState(() {
        _allCampaigns = campaigns;
        _isLoadingAll = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load campaigns: $e';
        _isLoadingAll = false;
      });
    }
  }

  Future<void> _loadPersonalizedCampaigns() async {
    setState(() {
      _isLoadingPersonalized = true;
      _error = null;
    });

    try {
      // For personalized campaigns, we'll use recommendations
      final campaigns = await ApiService.getRecommendedCampaigns();
      setState(() {
        _personalizedCampaigns = campaigns;
        _isLoadingPersonalized = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load personalized campaigns: $e';
        _isLoadingPersonalized = false;
      });
    }
  }

  List<Campaign> _getFilteredCampaigns(List<Campaign> campaigns) {
    if (_selectedCategory == 'Tümü') {
      return campaigns;
    }
    return campaigns.where((campaign) => campaign.category == _selectedCategory).toList();
  }

  Widget _buildCampaignList(List<Campaign> campaigns, bool isLoading) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Kampanyalar yüklenirken bir hata oluştu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _tabController.index == 0
                  ? _loadAllCampaigns
                  : _loadPersonalizedCampaigns,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final filteredCampaigns = _getFilteredCampaigns(campaigns);

    if (filteredCampaigns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _selectedCategory == 'Tümü'
                  ? 'Henüz kampanya yok'
                  : '$_selectedCategory kategorisinde kampanya bulunamadı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Daha sonra tekrar kontrol edin',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (_tabController.index == 0) {
          await _loadAllCampaigns();
        } else {
          await _loadPersonalizedCampaigns();
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: filteredCampaigns.length,
        itemBuilder: (context, index) {
          final campaign = filteredCampaigns[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: CampaignTemplate(
              campaign: campaign,
              style: CampaignTemplateStyle.card,
              width: double.infinity,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            title: const Text(
              'Kampanyalar',
              style: TextStyle(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.search,
                  color: AppTheme.textPrimaryColor,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CampaignDiscoveryScreen(),
                    ),
                  );
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryColor,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.textSecondaryColor,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 16,
              ),
              tabs: const [
                Tab(text: 'Tüm Kampanyalar'),
                Tab(text: 'Özel Kampanyalar'),
              ],
            ),
          ),
          body: Column(
            children: [
              // Category chips
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category['name'];
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          category['display'] ?? category['name'],
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textPrimaryColor,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        avatar: Icon(
                          category['icon'] as IconData,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.primaryColor,
                          size: 16,
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category['name'];
                          });
                        },
                        backgroundColor: Colors.grey[100],
                        selectedColor: AppTheme.primaryColor,
                        checkmarkColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // All Campaigns Tab
                    _buildCampaignList(_allCampaigns, _isLoadingAll),
                    
                    // Special for You Tab
                    _buildCampaignList(_personalizedCampaigns, _isLoadingPersonalized),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 