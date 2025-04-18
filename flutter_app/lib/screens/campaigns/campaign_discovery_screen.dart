import 'package:flutter/material.dart';
import 'package:payviya_app/core/theme/app_theme.dart';
import 'package:payviya_app/models/campaign.dart';
import 'package:payviya_app/screens/campaigns/campaign_detail_screen.dart';
import 'package:payviya_app/services/api_service.dart';

class CampaignDiscoveryScreen extends StatefulWidget {
  const CampaignDiscoveryScreen({super.key});

  @override
  State<CampaignDiscoveryScreen> createState() => _CampaignDiscoveryScreenState();
}

class _CampaignDiscoveryScreenState extends State<CampaignDiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  String _selectedFilter = 'Hepsi';
  bool _isLoading = true;
  String? _errorMessage;
  
  // Filters for campaigns
  final List<String> _filters = [
    'Hepsi', 
    'Popüler', 
    'Yeni', 
    'Süre Biten', 
    'Nakit İade'
  ];
  
  // Campaign data
  List<Campaign> _campaigns = [];
  
  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // Load campaigns from API
  Future<void> _loadCampaigns() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final campaigns = await ApiService.getCampaigns();
      setState(() {
        _campaigns = campaigns;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Kampanyalar yüklenirken bir hata oluştu: $e';
        _isLoading = false;
      });
    }
  }
  
  // Search campaigns from API
  Future<void> _searchCampaigns(String query) async {
    if (query.isEmpty) {
      _loadCampaigns();
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final campaigns = await ApiService.searchCampaigns(query);
      setState(() {
        _campaigns = campaigns;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Kampanyalar aranırken bir hata oluştu: $e';
        _isLoading = false;
      });
    }
  }
  
  // Filter campaigns based on selected filter
  List<Campaign> _getFilteredCampaigns() {
    if (_selectedFilter == 'Hepsi') {
      return _campaigns;
    } else if (_selectedFilter == 'Popüler') {
      return _campaigns.where((campaign) => campaign.priority > 5).toList();
    } else if (_selectedFilter == 'Yeni') {
      final now = DateTime.now();
      return _campaigns.where((campaign) => 
        now.difference(campaign.createdAt).inDays < 7
      ).toList();
    } else if (_selectedFilter == 'Süre Biten') {
      final now = DateTime.now();
      return _campaigns.where((campaign) => 
        campaign.endDate.difference(now).inDays < 7 && !campaign.isExpired
      ).toList();
    } else if (_selectedFilter == 'Nakit İade') {
      return _campaigns.where((campaign) => 
        campaign.discountType == 'cashback'
      ).toList();
    }
    
    return _campaigns;
  }

  @override
  Widget build(BuildContext context) {
    final filteredCampaigns = _getFilteredCampaigns();
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Kampanya ara...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.black87, fontSize: 17),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                onSubmitted: (value) {
                  _searchCampaigns(value);
                },
              )
            : const Text('Kampanyaları Keşfet'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                  _loadCampaigns();
                }
                _isSearching = !_isSearching;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade700,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Campaign List
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 80,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Hata Oluştu',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadCampaigns,
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  )
                : filteredCampaigns.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Kampanya bulunamadı',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Farklı bir arama yapmayı deneyin',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadCampaigns,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredCampaigns.length,
                        itemBuilder: (context, index) {
                          final campaign = filteredCampaigns[index];
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CampaignDetailScreen(campaignId: campaign.id),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Campaign header (bank logo, name, discount)
                                    Row(
                                      children: [
                                        // Bank logo or placeholder
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: campaign.bank?.logoUrl != null
                                            ? Image.network(
                                                campaign.bank!.logoUrl!,
                                                errorBuilder: (context, error, stackTrace) => 
                                                  Center(
                                                    child: Text(
                                                      campaign.bank!.name.substring(0, 1),
                                                      style: TextStyle(
                                                        color: AppTheme.primaryColor,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                              )
                                            : Center(
                                                child: Text(
                                                  campaign.bank?.name.substring(0, 1) ?? 'P',
                                                  style: TextStyle(
                                                    color: AppTheme.primaryColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                        ),
                                        const SizedBox(width: 12),
                                        
                                        // Campaign name and bank name
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                campaign.name,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                campaign.bank?.name ?? 'Unknown Bank',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Discount badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor,
                                            borderRadius: BorderRadius.circular(30),
                                          ),
                                          child: Text(
                                            campaign.formattedDiscount,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Campaign description
                                    Text(
                                      campaign.description,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Campaign metadata (end date, category)
                                    Row(
                                      children: [
                                        // End date
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          campaign.timeRemaining,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        
                                        const SizedBox(width: 16),
                                        
                                        // Category
                                        Icon(
                                          Icons.category_outlined,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          campaign.category,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        
                                        const Spacer(),
                                        
                                        // Card name if available
                                        if (campaign.creditCard != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              campaign.creditCard!.name,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade800,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
} 