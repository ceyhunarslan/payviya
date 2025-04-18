import 'package:flutter/material.dart';
import 'package:payviya_app/core/theme/app_theme.dart';
import 'package:payviya_app/screens/campaigns/campaign_detail_screen.dart';
import 'package:payviya_app/screens/campaigns/campaign_discovery_screen.dart';

class CampaignsTab extends StatefulWidget {
  const CampaignsTab({Key? key}) : super(key: key);

  @override
  State<CampaignsTab> createState() => _CampaignsTabState();
}

class _CampaignsTabState extends State<CampaignsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Mock campaign data
  final List<Map<String, dynamic>> _activeCampaigns = [
    {
      'id': 'camp_001',
      'title': 'Süpermarket İndirimi',
      'description': 'Migros alışverişlerinizde %10 indirim kazanın.',
      'merchant': 'Migros',
      'merchantLogo': 'assets/images/logos/migros.png',
      'bankName': 'Akbank',
      'cardType': 'Axess',
      'expiryDate': '30 Haziran 2023',
      'discountRate': 10,
      'discountType': 'percentage',
      'backgroundColor': const Color(0xFFF44336),
      'progress': 0.4,
      'spentAmount': 560.25,
      'targetAmount': 1000.0,
      'category': 'Süpermarket',
      'usersJoined': 256,
    },
    {
      'id': 'camp_002',
      'title': 'Akaryakıt Kampanyası',
      'description': 'BP istasyonlarında 500 TL ve üzeri harcamalarda 50 TL indirim.',
      'merchant': 'BP',
      'merchantLogo': 'assets/images/logos/bp.png',
      'bankName': 'Garanti BBVA',
      'cardType': 'Bonus',
      'expiryDate': '15 Temmuz 2023',
      'discountRate': 50,
      'discountType': 'fixed',
      'backgroundColor': const Color(0xFF4CAF50),
      'progress': 0.7,
      'spentAmount': 350.0,
      'targetAmount': 500.0,
      'category': 'Akaryakıt',
      'usersJoined': 512,
    },
    {
      'id': 'camp_003',
      'title': 'Online Alışveriş Fırsatı',
      'description': 'Trendyol\'da 1000 TL üzeri alışverişlerde 150 TL indirim.',
      'merchant': 'Trendyol',
      'merchantLogo': 'assets/images/logos/trendyol.png',
      'bankName': 'Yapı Kredi',
      'cardType': 'World',
      'expiryDate': '20 Temmuz 2023',
      'discountRate': 150,
      'discountType': 'fixed',
      'backgroundColor': const Color(0xFFFF9800),
      'progress': 0.2,
      'spentAmount': 200.0,
      'targetAmount': 1000.0,
      'category': 'E-Ticaret',
      'usersJoined': 384,
    },
  ];
  
  final List<Map<String, dynamic>> _recommendedCampaigns = [
    {
      'id': 'rec_001',
      'title': 'Yemek Siparişi İndirimi',
      'description': 'Yemeksepeti\'nde her hafta %15 indirim kazanın.',
      'merchant': 'Yemeksepeti',
      'merchantLogo': 'assets/images/logos/yemeksepeti.png',
      'bankName': 'QNB Finansbank',
      'cardType': 'CardFinans',
      'discountRate': 15,
      'discountType': 'percentage',
      'backgroundColor': const Color(0xFF9C27B0),
      'category': 'Yemek',
      'compatibilityScore': 92,
    },
    {
      'id': 'rec_002',
      'title': 'Kahve Keyfi',
      'description': 'Starbucks\'ta 2 kahve alana 1 kahve bedava.',
      'merchant': 'Starbucks',
      'merchantLogo': 'assets/images/logos/starbucks.png',
      'bankName': 'İş Bankası',
      'cardType': 'Maximum',
      'discountRate': 33,
      'discountType': 'percentage',
      'backgroundColor': const Color(0xFF009688),
      'category': 'Kafe',
      'compatibilityScore': 87,
    },
    {
      'id': 'rec_003',
      'title': 'Elektronik Alışverişi',
      'description': 'MediaMarkt\'ta 3000 TL üzeri alışverişlerde 300 TL indirim.',
      'merchant': 'MediaMarkt',
      'merchantLogo': 'assets/images/logos/mediamarkt.png',
      'bankName': 'Garanti BBVA',
      'cardType': 'Bonus',
      'discountRate': 300,
      'discountType': 'fixed',
      'backgroundColor': const Color(0xFF2196F3),
      'category': 'Elektronik',
      'compatibilityScore': 78,
    },
  ];
  
  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Tümü',
      'icon': Icons.all_inclusive,
    },
    {
      'name': 'Süpermarket',
      'icon': Icons.shopping_cart,
    },
    {
      'name': 'Akaryakıt',
      'icon': Icons.local_gas_station,
    },
    {
      'name': 'Yemek',
      'icon': Icons.restaurant,
    },
    {
      'name': 'Elektronik',
      'icon': Icons.devices,
    },
    {
      'name': 'Giyim',
      'icon': Icons.checkroom,
    },
    {
      'name': 'Eğlence',
      'icon': Icons.movie,
    },
  ];
  
  String _selectedCategory = 'Tümü';
  
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Debug print to check categories
    print('Category list names: ${_categories.map((c) => c['name']).toList()}');
    print('Active campaign categories: ${_activeCampaigns.map((c) => c['category']).toSet().toList()}');
    print('Recommended campaign categories: ${_recommendedCampaigns.map((c) => c['category']).toSet().toList()}');
    
    // Make sure categories are consistent
    for (var campaign in _activeCampaigns) {
      if (campaign['category'] is String) {
        // Convert to properly match category names in the _categories list
        String categoryName = campaign['category'];
        var matchedCategory = _categories.firstWhere(
          (cat) => cat['name'].toString().toLowerCase() == categoryName.toLowerCase(),
          orElse: () => {'name': categoryName, 'icon': Icons.category}
        );
        
        if (matchedCategory != null) {
          campaign['category'] = matchedCategory['name'];
        }
      }
    }
    
    for (var campaign in _recommendedCampaigns) {
      if (campaign['category'] is String) {
        // Convert to properly match category names in the _categories list
        String categoryName = campaign['category'];
        var matchedCategory = _categories.firstWhere(
          (cat) => cat['name'].toString().toLowerCase() == categoryName.toLowerCase(),
          orElse: () => {'name': categoryName, 'icon': Icons.category}
        );
        
        if (matchedCategory != null) {
          campaign['category'] = matchedCategory['name'];
        }
      }
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                Tab(text: 'Aktif'),
                Tab(text: 'Önerilen'),
              ],
            ),
          ),
          body: Column(
            children: [
              // Category selector
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category['name'] == _selectedCategory;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category['name'];
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.lightBlue : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                category['icon'],
                                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                category['name'],
                                style: TextStyle(
                                  color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Active campaigns tab
                    _buildActiveCampaignsTab(),
                    
                    // Recommended campaigns tab
                    _buildRecommendedCampaignsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveCampaignsTab() {
    var filteredCampaigns = _activeCampaigns;
    
    // Filter campaigns by selected category if one is selected
    if (_selectedCategory != null && _selectedCategory != "Tümü") {
      print('Filtering active campaigns by category: $_selectedCategory');
      
      filteredCampaigns = _activeCampaigns.where((campaign) {
        // Make sure we're comparing strings properly
        String campaignCategory = campaign['category']?.toString() ?? '';
        bool matches = campaignCategory.toLowerCase() == _selectedCategory.toLowerCase();
        
        // Debug print for troubleshooting
        if (_activeCampaigns.length < 10) { // Only log if not too many campaigns
          print('Campaign: ${campaign['title']} - Category: $campaignCategory - Selected: $_selectedCategory - Matches: $matches');
        }
        
        return matches;
      }).toList();
      
      print('Found ${filteredCampaigns.length} matching active campaigns');
    }
    
    if (filteredCampaigns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedCategory == 'Tümü' 
                ? 'Aktif kampanya bulunmamaktadır.' 
                : '$_selectedCategory kategorisinde kampanya bulunmamaktadır.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _isLoading = true;
        });
        
        // Simulate API call
        await Future.delayed(const Duration(seconds: 1));
        
        setState(() {
          _isLoading = false;
        });
      },
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredCampaigns.length,
        itemBuilder: (context, index) {
          final campaign = filteredCampaigns[index];
          
          return _buildActiveCampaignCard(campaign);
        },
      ),
    );
  }
  
  Widget _buildActiveCampaignCard(Map<String, dynamic> campaign) {
    final Color backgroundColor = campaign['backgroundColor'];
    final double progress = campaign['progress'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CampaignDetailScreen(campaignId: campaign['id']),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bank and card info
                Row(
                  children: [
                    // Bank logo placeholder
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          campaign['bankName'][0],
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${campaign['bankName']} ${campaign['cardType']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Premium badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.amber.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Premium',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Son tarih: ${campaign['expiryDate']}',
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Campaign title and merchant
                Text(
                  campaign['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Merchant logo placeholder
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          campaign['merchant'][0],
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      campaign['merchant'],
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: backgroundColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        campaign['category'],
                        style: TextStyle(
                          color: backgroundColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Description
                Text(
                  campaign['description'],
                  style: const TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Progress
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Stack(
                              children: [
                                // Background
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                // Progress
                                FractionallySizedBox(
                                  widthFactor: progress,
                                  child: Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: backgroundColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Progress text
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '₺${campaign['spentAmount']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                              Text(
                                'Hedef: ₺${campaign['targetAmount']}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Discount badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        campaign['discountType'] == 'percentage'
                            ? '%${campaign['discountRate']}'
                            : '${campaign['discountRate']} TL',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Add "Kampanyaya Katıl" button with premium check for active campaigns
                const SizedBox(height: 16),
                Visibility(
                  visible: false, // Hidden until bank partnership
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showPremiumDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: backgroundColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Kampanyaya Katıl',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPremiumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Premium Özellik'),
          content: const Text('Bu özelliği kullanabilmek için premium üyelik gereklidir.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kapat'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to premium subscription page
                // TODO: Add navigation to premium subscription page
              },
              child: const Text('Premium Ol', style: TextStyle(color: AppTheme.primaryColor)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecommendedCampaignsTab() {
    var filteredCampaigns = _recommendedCampaigns;
    
    // Filter campaigns by selected category if one is selected
    if (_selectedCategory != null && _selectedCategory != "Tümü") {
      print('Filtering recommended campaigns by category: $_selectedCategory');
      
      filteredCampaigns = _recommendedCampaigns.where((campaign) {
        // Make sure we're comparing strings properly
        String campaignCategory = campaign['category']?.toString() ?? '';
        bool matches = campaignCategory.toLowerCase() == _selectedCategory.toLowerCase();
        
        // Debug print for troubleshooting
        if (_recommendedCampaigns.length < 10) { // Only log if not too many campaigns
          print('Campaign: ${campaign['title']} - Category: $campaignCategory - Selected: $_selectedCategory - Matches: $matches');
        }
        
        return matches;
      }).toList();
      
      print('Found ${filteredCampaigns.length} matching recommended campaigns');
    }
    
    if (filteredCampaigns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedCategory == 'Tümü' 
                ? 'Önerilen kampanya bulunmamaktadır.' 
                : '$_selectedCategory kategorisinde önerilen kampanya bulunmamaktadır.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _isLoading = true;
        });
        
        // Simulate API call
        await Future.delayed(const Duration(seconds: 1));
        
        setState(() {
          _isLoading = false;
        });
      },
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredCampaigns.length,
        itemBuilder: (context, index) {
          final campaign = filteredCampaigns[index];
          
          return _buildRecommendedCampaignCard(campaign);
        },
      ),
    );
  }
  
  Widget _buildRecommendedCampaignCard(Map<String, dynamic> campaign) {
    final Color backgroundColor = campaign['backgroundColor'];
    final int compatibilityScore = campaign['compatibilityScore'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CampaignDetailScreen(campaignId: campaign['id']),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bank and card info
                Row(
                  children: [
                    // Bank logo placeholder
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          campaign['bankName'][0],
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${campaign['bankName']} ${campaign['cardType']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Premium badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.amber.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Premium',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Campaign title and merchant
                Text(
                  campaign['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Merchant logo placeholder
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          campaign['merchant'][0],
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      campaign['merchant'],
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: backgroundColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        campaign['category'],
                        style: TextStyle(
                          color: backgroundColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Description
                Text(
                  campaign['description'],
                  style: const TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Compatibility score and discount badge in a row (like the progress row)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade100),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: Colors.green,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Uyumluluk: %$compatibilityScore',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Discount badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        campaign['discountType'] == 'percentage'
                            ? '%${campaign['discountRate']}'
                            : '${campaign['discountRate']} TL',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Apply button
                const SizedBox(height: 16),
                Visibility(
                  visible: false, // Hidden until bank partnership
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showPremiumDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: backgroundColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Kampanyayı Kullan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 