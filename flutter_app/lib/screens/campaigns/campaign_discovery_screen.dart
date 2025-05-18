import 'package:flutter/material.dart';
import 'package:payviya_app/core/theme/app_theme.dart';
import 'package:payviya_app/models/campaign.dart';
import 'package:payviya_app/models/credit_card.dart';
import 'package:payviya_app/screens/campaigns/campaign_detail_screen.dart';
import 'package:payviya_app/services/api_service.dart';
import 'package:payviya_app/services/campaign_service.dart';
import 'package:payviya_app/widgets/campaign_template.dart';
import 'package:payviya_app/widgets/loading_indicator.dart';
import 'package:payviya_app/utils/logo_helper.dart';
import 'package:payviya_app/widgets/user_avatar.dart';
import 'package:payviya_app/widgets/notification_icon_with_badge.dart';
import 'package:payviya_app/services/user_service.dart';
import 'package:payviya_app/services/navigation_service.dart';

class CampaignDiscoveryScreen extends StatefulWidget {
  final bool showAppBar;
  
  const CampaignDiscoveryScreen({
    Key? key,
    this.showAppBar = true,
  }) : super(key: key);

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
  String _userName = '';
  String _userSurname = '';
  
  // Category data
  List<Map<String, dynamic>> _categories = [];
  String _selectedCategory = 'Tümü';
  
  // Credit card data
  List<CreditCardListItem> _creditCards = [];
  String _selectedCard = 'Tümü';
  
  final Map<String, IconData> _categoryIcons = {
    'Tümü': Icons.all_inclusive,
    'GROCERY': Icons.shopping_cart,
    'TRAVEL': Icons.flight,
    'ELECTRONICS': Icons.devices,
    'FUEL': Icons.local_gas_station,
    'ENTERTAINMENT': Icons.movie,
    'FASHION': Icons.shopping_bag,
    'RESTAURANT': Icons.restaurant,
    'OTHER': Icons.more_horiz,
  };
  
  final Map<String, String> _categoryDisplayNames = {
    'Tümü': 'Tümü',
    'GROCERY': 'Süpermarket',
    'TRAVEL': 'Seyahat',
    'ELECTRONICS': 'Elektronik',
    'FUEL': 'Akaryakıt',
    'ENTERTAINMENT': 'Eğlence',
    'FASHION': 'Moda',
    'RESTAURANT': 'Restoran',
    'OTHER': 'Diğer',
  };
  
  // Filters for campaigns
  final List<String> _filters = ['Hepsi', 'Popüler', 'Yeni', 'Süre Biten', 'Nakit İade'];
  
  // Campaign data
  List<Campaign> _campaigns = [];
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCategories();
    _loadCreditCards();
    _loadCampaigns();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    try {
      final response = await ApiService.get('/users/me');
      if (response != null) {
        setState(() {
          _userName = response['name'] ?? '';
          _userSurname = response['surname'] ?? '';
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }
  
  Future<void> _loadCategories() async {
    try {
      final apiCategories = await ApiService.getCampaignCategories();
      setState(() {
        _categories = [
          {
            'name': 'Tümü',
            'icon': _categoryIcons['Tümü'],
            'display': 'Tümü',
            'id': null,
          },
          ...apiCategories.map((category) => {
            'name': category['name'],
            'icon': _categoryIcons[category['enum']] ?? Icons.category,
            'display': _categoryDisplayNames[category['enum']] ?? category['name'],
            'id': category['id'],
            'enum': category['enum'],
            'icon_url': category['icon_url'],
            'color': category['color'],
          }).toList(),
        ];
      });
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        _categories = [
          {
            'name': 'Tümü',
            'icon': Icons.all_inclusive,
            'display': 'Tümü',
            'id': null,
          },
        ];
      });
    }
  }
  
  Future<void> _loadCreditCards() async {
    try {
      final response = await ApiService.instance.dio.get('/credit-cards/');
      
      if (mounted) {
        // Parse available cards
        final cards = (response.data as List).map((card) => CreditCardListItem(
          id: card['credit_card_id'],
          creditCardId: card['credit_card_id'],
          creditCardName: card['credit_card_name'],
          creditCardLogoUrl: card['credit_card_logo_url'],
          bankName: card['bank_name'],
          bankLogoUrl: card['bank_logo_url'],
        )).toList();

        setState(() {
          _creditCards = cards;
        });
      }
    } catch (e) {
      print('Error loading credit cards: $e');
    }
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
  
  // Filter campaigns based on selected filter, category and card
  List<Campaign> _getFilteredCampaigns() {
    var filteredCampaigns = _campaigns;
    
    // First apply category filter
    if (_selectedCategory != 'Tümü') {
      final selectedCategoryId = _categories
          .firstWhere((cat) => cat['name'] == _selectedCategory)['id'] as int?;
      
      if (selectedCategoryId != null) {
        filteredCampaigns = filteredCampaigns
            .where((campaign) => campaign.categoryId == selectedCategoryId)
            .toList();
      }
    }
    
    // Then apply card filter
    if (_selectedCard != 'Tümü') {
      final selectedCard = _creditCards.firstWhere((card) => card.creditCardName == _selectedCard);
      filteredCampaigns = filteredCampaigns
          .where((campaign) => campaign.creditCard?.id == selectedCard.creditCardId)
          .toList();
    }
    
    // Then apply type filter
    if (_selectedFilter == 'Hepsi') {
      return filteredCampaigns;
    } else if (_selectedFilter == 'Popüler') {
      return filteredCampaigns.where((campaign) => campaign.priority > 5).toList();
    } else if (_selectedFilter == 'Yeni') {
      final now = DateTime.now();
      return filteredCampaigns.where((campaign) => 
        now.difference(campaign.createdAt).inDays < 7
      ).toList();
    } else if (_selectedFilter == 'Süre Biten') {
      final now = DateTime.now();
      return filteredCampaigns.where((campaign) => 
        campaign.endDate.difference(now).inDays < 7 && !campaign.isExpired
      ).toList();
    } else if (_selectedFilter == 'Nakit İade') {
      return filteredCampaigns.where((campaign) => 
        campaign.discountType == DiscountType.CASHBACK
      ).toList();
    }
    
    return filteredCampaigns;
  }

  // Show category filter modal
  void _showCategoryFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Kategori Seç',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  // Category list
                  Expanded(
                    child: ListView.builder(
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = _selectedCategory == category['name'];
                        
                        return ListTile(
                          leading: Icon(
                            category['icon'] as IconData,
                            color: isSelected ? AppTheme.primaryColor : Colors.grey,
                          ),
                          title: Text(
                            category['display'] ?? category['name'],
                            style: TextStyle(
                              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade700,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          trailing: isSelected ? const Icon(
                            Icons.check_circle,
                            color: AppTheme.primaryColor,
                          ) : null,
                          tileColor: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
                          onTap: () {
                            setState(() {
                              _selectedCategory = category['name'];
                            });
                          },
                        );
                      },
                    ),
                  ),
                  // Apply button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      this.setState(() {}); // Refresh main screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Uygula',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Show card filter modal
  void _showCardFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Kart Seç',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  // Card list
                  Expanded(
                    child: ListView.builder(
                      itemCount: _creditCards.length + 1, // +1 for "Tümü"
                      itemBuilder: (context, index) {
                        final isAll = index == 0;
                        final card = isAll ? null : _creditCards[index - 1];
                        final isSelected = isAll 
                            ? _selectedCard == 'Tümü'
                            : _selectedCard == (card!.creditCardName ?? 'Bilinmeyen Kart');
                        
                        return ListTile(
                          leading: isAll 
                              ? const Icon(Icons.credit_card)
                              : (card!.bankLogoUrl != null
                                  ? Image.network(
                                      card.bankLogoUrl!,
                                      width: 24,
                                      height: 24,
                                      errorBuilder: (context, error, stackTrace) => 
                                          const Icon(Icons.credit_card),
                                    )
                                  : const Icon(Icons.credit_card)),
                          title: Text(
                            isAll ? 'Tümü' : (card!.creditCardName ?? 'Bilinmeyen Kart'),
                            style: TextStyle(
                              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade700,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          trailing: isSelected ? const Icon(
                            Icons.check_circle,
                            color: AppTheme.primaryColor,
                          ) : null,
                          tileColor: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
                          onTap: () {
                            setState(() {
                              _selectedCard = isAll ? 'Tümü' : (card!.creditCardName ?? 'Bilinmeyen Kart');
                            });
                          },
                        );
                      },
                    ),
                  ),
                  // Apply button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      this.setState(() {}); // Refresh main screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Uygula',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCampaigns = _getFilteredCampaigns();
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            if (widget.showAppBar)
              SliverAppBar(
                floating: true,
                pinned: false,
                snap: true,
                backgroundColor: Colors.white,
                elevation: 0,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    UserAvatar(
                      name: _userName,
                      surname: _userSurname,
                      radius: 18,
                      backgroundColor: AppTheme.primaryColor,
                      textColor: Colors.white,
                      fontSize: 16,
                      enableTap: true,
                    ),
                    const Expanded(
                      child: Text(
                        'Kampanyalar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const NotificationIconWithBadge(),
                  ],
                ),
              ),

            // Search bar (if searching)
            if (_isSearching)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Kampanya ara...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                            _isSearching = false;
                            _loadCampaigns();
                          });
                        },
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    onSubmitted: (value) {
                      _searchCampaigns(value);
                    },
                  ),
                ),
              ),

            // Category and card filters
            SliverAppBar(
              floating: false,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showCategoryFilterModal,
                        icon: Icon(
                          _categoryIcons[_selectedCategory] ?? Icons.category,
                          size: 16,
                          color: _selectedCategory != 'Tümü'
                              ? AppTheme.primaryColor
                              : Colors.grey,
                        ),
                        label: Text(
                          _selectedCategory != 'Tümü'
                              ? (_categoryDisplayNames[_selectedCategory] ?? _selectedCategory)
                              : 'Kategori',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _selectedCategory != 'Tümü'
                                ? AppTheme.primaryColor
                                : Colors.grey,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _selectedCategory != 'Tümü'
                              ? AppTheme.primaryColor
                              : Colors.grey,
                          side: BorderSide(
                            color: _selectedCategory != 'Tümü'
                                ? AppTheme.primaryColor
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showCardFilterModal,
                        icon: Icon(
                          Icons.credit_card,
                          size: 16,
                          color: _selectedCard != 'Tümü'
                              ? AppTheme.primaryColor
                              : Colors.grey,
                        ),
                        label: Text(
                          _selectedCard == 'Tümü' ? 'Kart' : _selectedCard,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _selectedCard != 'Tümü'
                                ? AppTheme.primaryColor
                                : Colors.grey,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _selectedCard != 'Tümü'
                              ? AppTheme.primaryColor
                              : Colors.grey,
                          side: BorderSide(
                            color: _selectedCard != 'Tümü'
                                ? AppTheme.primaryColor
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Campaign list
            _isLoading
                ? const SliverFillRemaining(
                    child: Center(child: LoadingIndicator()),
                  )
                : _errorMessage != null
                    ? SliverFillRemaining(
                        child: Center(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      )
                    : filteredCampaigns.isEmpty
                        ? SliverFillRemaining(
                            child: Center(
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
                                    'Kampanya bulunamadı',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final campaign = filteredCampaigns[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                                  child: CampaignTemplate(
                                    campaign: campaign,
                                    style: CampaignTemplateStyle.discover,
                                    onTap: () {
                                      NavigationService.navigateToCampaignDetail(campaign);
                                    },
                                  ),
                                );
                              },
                              childCount: filteredCampaigns.length,
                            ),
                          ),
          ],
        ),
      ),
    );
  }
} 